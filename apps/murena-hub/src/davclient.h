#pragma once
#include <QObject>
#include <QVariantList>
#include <QNetworkAccessManager>
class DavClient : public QObject {
 Q_OBJECT
 Q_PROPERTY(QVariantList entries READ entries NOTIFY entriesChanged)
 Q_PROPERTY(QString error READ error NOTIFY errorChanged)
public:
 explicit DavClient(QObject *p=nullptr):QObject(p){}
 QVariantList entries() const{return m_entries;}
 QString error() const{return m_error;}
 Q_INVOKABLE void list(const QString &url,const QString &user,const QString &password);
 Q_INVOKABLE void download(const QString &url,const QString &user,const QString &password,const QString &name);
signals:
 void entriesChanged(); void errorChanged();
 void downloaded(const QString &localUrl,const QString &mime,const QString &name);
private:
 void setError(const QString &s);
 QNetworkRequest request(const QUrl &url,const QString &user,const QString &password) const;
 QNetworkAccessManager m_net; QVariantList m_entries; QString m_error;
};