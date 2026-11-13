#include "wordpredictor.h"

#include <QFileInfo>
#include <QLoggingCategory>

#include <hunspell/hunspell.h>

Q_LOGGING_CATEGORY(lcWordPredictor, "moarchy.words")

WordPredictor::WordPredictor(const QString &affPath, const QString &dicPath,
                             QObject *parent)
    : QObject(parent)
{
    const QFileInfo aff(affPath), dic(dicPath);
    if (!aff.isReadable() || !dic.isReadable()) {
        qCInfo(lcWordPredictor) << "Polish dictionary not installed; word suggestions disabled";
        return;
    }

    const QByteArray affUtf8 = aff.absoluteFilePath().toUtf8();
    const QByteArray dicUtf8 = dic.absoluteFilePath().toUtf8();
    m_hunspell = Hunspell_create(affUtf8.constData(), dicUtf8.constData());
    if (!m_hunspell)
        qCWarning(lcWordPredictor) << "could not load Polish Hunspell dictionary";
    else
        qCInfo(lcWordPredictor) << "offline Polish spelling suggestions ready";
}

WordPredictor::~WordPredictor()
{
    if (m_hunspell)
        Hunspell_destroy(m_hunspell);
}

QStringList WordPredictor::suggestions(const QString &word) const
{
    if (!m_hunspell || word.size() < 3 || word.size() > 48)
        return {};

    // Do not suggest replacements for words already accepted by the dictionary.
    const QByteArray utf8 = word.toUtf8();
    if (Hunspell_spell(m_hunspell, utf8.constData()) != 0)
        return {};

    char **raw = nullptr;
    const int count = Hunspell_suggest(m_hunspell, &raw, utf8.constData());
    QStringList result;
    for (int i = 0; i < count && result.size() < 3; ++i) {
        const QString candidate = QString::fromUtf8(raw[i]);
        if (!candidate.isEmpty() && candidate.compare(word, Qt::CaseInsensitive) != 0)
            result.append(candidate);
    }
    if (raw)
        Hunspell_free_list(m_hunspell, &raw, count);
    return result;
}
