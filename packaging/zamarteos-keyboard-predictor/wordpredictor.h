#pragma once

#include "qmlsingleton.h"

#include <QObject>
#include <QStringList>

struct Hunhandle;

// Offline Polish spelling suggestions. It never reads text from the focused
// application: QML supplies only the word the user has typed on this keyboard.
class WordPredictor : public QObject, public MainOwnedSingleton<WordPredictor>
{
    Q_OBJECT
    QML_NAMED_ELEMENT(WordPredictor)
    QML_SINGLETON

public:
    explicit WordPredictor(const QString &affPath, const QString &dicPath,
                           QObject *parent = nullptr);
    ~WordPredictor() override;

    Q_INVOKABLE QStringList suggestions(const QString &word) const;
    bool available() const { return m_hunspell != nullptr; }

private:
    Hunhandle *m_hunspell = nullptr;
};

MOARCHY_SINGLETON_INVARIANT(WordPredictor);
