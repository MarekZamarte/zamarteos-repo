#!/usr/bin/env python3
"""Apply the reviewed ZamarteOS offline Polish suggestions patch to pinned moarchy-keyboard."""
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()

def replace(path, old, new, label):
    p = root / path
    s = p.read_text(encoding="utf-8")
    if new in s:
        return
    if old not in s:
        raise SystemExit(f"{path}: expected insertion point missing ({label})")
    p.write_text(s.replace(old, new, 1), encoding="utf-8")

# CMake: build the small Hunspell-backed QObject into the keyboard.
replace("CMakeLists.txt",
'''pkg_check_modules(XkbCommon REQUIRED IMPORTED_TARGET xkbcommon)
''',
'''pkg_check_modules(XkbCommon REQUIRED IMPORTED_TARGET xkbcommon)
pkg_check_modules(Hunspell REQUIRED IMPORTED_TARGET hunspell)
''', "Hunspell pkg-config dependency")
replace("CMakeLists.txt",
'''  src/keyrouter.cpp
  src/theme.cpp
''',
'''  src/keyrouter.cpp
  src/wordpredictor.cpp
  src/wordpredictor.h
  src/theme.cpp
''', "WordPredictor sources")
replace("CMakeLists.txt",
'''  PkgConfig::XkbCommon
''',
'''  PkgConfig::XkbCommon
  PkgConfig::Hunspell
''', "Hunspell link")

# Register the main-owned singleton before QML loads.
replace("src/main.cpp",
'''#include "waylandconnection.h"
''',
'''#include "waylandconnection.h"
#include "wordpredictor.h"
''', "WordPredictor include")
replace("src/main.cpp",
'''    KeyRouter router(&inputMethod, &virtualKeyboard);

    Theme theme(nullptr);
''',
'''    KeyRouter router(&inputMethod, &virtualKeyboard);
    WordPredictor wordPredictor(
        QStringLiteral("/usr/share/hunspell/pl_PL.aff"),
        QStringLiteral("/usr/share/hunspell/pl_PL.dic"));
    WordPredictor::setInstance(&wordPredictor);

    Theme theme(nullptr);
''', "WordPredictor instance")

# Keep the keyboard geometry stable: the suggestion strip takes 34px from
# the four key rows, rather than pushing the bottom row under the home gesture.
replace("qml/Keyboard.qml",
'''    readonly property real rowHeight: rows.length > 0 ? height / rows.length : height
''',
'''    readonly property real suggestionHeight: 34
    readonly property real rowHeight:
        rows.length > 0 ? (height - suggestionHeight) / rows.length : height
    property string composingWord: ""
    readonly property var wordSuggestions:
        Router.active && !Router.sensitive && Router.suggestedLayout === ""
            && layoutName === "letters" && composingWord.length >= 3
            && WordPredictor.available
            ? WordPredictor.suggestions(composingWord) : []

    function isPolishWordCharacter(value) {
        return /^[A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]+$/.test(value)
    }

    function noteTypedText(value) {
        if (value === " ") {
            composingWord = ""
        } else if (isPolishWordCharacter(value)) {
            composingWord += value
        } else {
            composingWord = ""
        }
    }

    function acceptWordSuggestion(candidate) {
        if (!Router.active || Router.sensitive || candidate === "")
            return
        for (var i = 0; i < composingWord.length; ++i)
            Router.sendKey("BackSpace", 0)
        Router.sendText(candidate + " ")
        composingWord = ""
    }
''', "word suggestion state and safe replacement")
replace("qml/Keyboard.qml",
'''    Connections {
        target: Router
        function onStateChanged() { keyboard.applySuggestion() }
''',
'''    Connections {
        target: Router
        function onStateChanged() {
            if (!Router.active || Router.sensitive || Router.suggestedLayout !== "")
                keyboard.composingWord = ""
            keyboard.applySuggestion()
        }
''', "clear composing word when input context changes")
replace("qml/Keyboard.qml",
'''            keyboard.layoutChosenByHand = false
            keyboard.ctrlState = 0
''',
'''            keyboard.layoutChosenByHand = false
            keyboard.composingWord = ""
            keyboard.ctrlState = 0
''', "clear composing word on focus change")
replace("qml/Keyboard.qml",
'''    Column {
        id: rowsColumn
        anchors.fill: parent
''',
'''    Rectangle {
        id: suggestionStrip
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: keyboard.suggestionHeight
        visible: keyboard.wordSuggestions.length > 0
        color: Colors.panelBackground
        z: 4

        Row {
            anchors.fill: parent
            Repeater {
                model: keyboard.wordSuggestions
                delegate: Item {
                    required property string modelData
                    width: suggestionStrip.width / 3
                    height: suggestionStrip.height

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Colors.keyText
                        font.pixelSize: 15
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: keyboard.acceptWordSuggestion(modelData)
                    }
                }
            }
        }
    }

    Column {
        id: rowsColumn
        anchors.fill: parent
        anchors.topMargin: keyboard.suggestionHeight
''', "suggestion strip UI")
replace("qml/Keyboard.qml",
'''        case KeyType.Action:
            Router.sendKey(spec.key, chordModifiers)
            consumeOneShots()
            return
''',
'''        case KeyType.Action:
            Router.sendKey(spec.key, chordModifiers)
            if (spec.key === "BackSpace")
                keyboard.composingWord = keyboard.composingWord.slice(0, -1)
            else if (spec.key === "Return")
                keyboard.composingWord = ""
            consumeOneShots()
            return
''', "composition tracking for backspace and enter")
replace("qml/Keyboard.qml",
'''        Router.sendText(shifted ? spec.shiftedText : text)
        consumeOneShots()
''',
'''        var emittedText = shifted ? spec.shiftedText : text
        Router.sendText(emittedText)
        keyboard.noteTypedText(emittedText)
        consumeOneShots()
''', "composition tracking for typed characters")
replace("qml/Keyboard.qml",
'''        if (value !== "")
            Router.sendText(value)
        consumeOneShots()
''',
'''        if (value !== "") {
            Router.sendText(value)
            keyboard.noteTypedText(value)
        }
        consumeOneShots()
''', "composition tracking for alternates")

# Bump the package and install the runtime dictionary and library. The build
# environment resolves these through makepkg's declared dependencies.
replace("packaging/PKGBUILD",
'''pkgrel=5
''',
'''pkgrel=6
''', "package release bump")
replace("packaging/PKGBUILD",
'''  'libxkbcommon'
)
''',
'''  'libxkbcommon'
  'hunspell'
  'hunspell-pl'
)
''', "runtime dictionary dependencies")

print("Applied ZamarteOS offline Polish spelling suggestions patch.")
