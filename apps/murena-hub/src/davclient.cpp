#include "davclient.h"
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QBuffer>
#include <QDomDocument>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QStandardPaths>
#include <QRegularExpression>
#include <QUrl>
void DavClient::setError(const QString&s){if(m_error==s)return;m_error=s;emit errorChanged();}
QNetworkRequest DavClient::request(const QUrl&u,const QString&user,const QString&pass)const{
 QNetworkRequest r(u);r.setRawHeader("Authorization","Basic "+(user+":"+pass).toUtf8().toBase64());
 r.setRawHeader("User-Agent","MurenaHub-Sailfish/0.2");return r;
}
void DavClient::list(const QString&url,const QString&user,const QString&pass){
 QUrl target(url.trimmed());
 if(!target.isValid()||(target.scheme()!="https"&&target.scheme()!="http")||user.isEmpty()||pass.isEmpty()){
 setError("Wpisz poprawny adres WebDAV, użytkownika i hasło aplikacji.");return;}
 QNetworkRequest r=request(target,user,pass);r.setRawHeader("Depth","1");r.setHeader(QNetworkRequest::ContentTypeHeader,"application/xml; charset=utf-8");
 QByteArray body="<?xml version=\"1.0\"?><d:propfind xmlns:d=\"DAV:\"><d:prop><d:displayname/><d:resourcetype/><d:getcontenttype/></d:prop></d:propfind>";
 QBuffer *bodyDevice=new QBuffer;
 bodyDevice->setData(body);
 bodyDevice->open(QIODevice::ReadOnly);
 QNetworkReply *rep=m_net.sendCustomRequest(r,"PROPFIND",bodyDevice);
 connect(rep,&QNetworkReply::finished,this,[this,rep,target,bodyDevice](){
 bodyDevice->deleteLater();
 QByteArray data=rep->readAll();int status=rep->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
 if(rep->error()!=QNetworkReply::NoError||(status!=207&&status!=200)){
 setError(status==401?"Nieprawidłowy login lub hasło aplikacji.":"Błąd WebDAV: "+rep->errorString());rep->deleteLater();return;}
 QDomDocument doc;if(!doc.setContent(data,true)){setError("Niepoprawna odpowiedź WebDAV.");rep->deleteLater();return;}
 QVariantList list;QDomNodeList nodes=doc.elementsByTagNameNS("DAV:","response");
 for(int i=0;i<nodes.size();++i){
 QDomElement e=nodes.at(i).toElement();QDomNodeList hs=e.elementsByTagNameNS("DAV:","href");if(hs.isEmpty())continue;
 QUrl resolved=target.resolved(QUrl(hs.at(0).toElement().text()));
 QString p=resolved.path();p.remove(QRegularExpression("/+$"));QString tp=target.path();tp.remove(QRegularExpression("/+$"));if(p==tp)continue;
 QDomNodeList ps=e.elementsByTagNameNS("DAV:","prop");QDomElement prop=ps.isEmpty()?QDomElement():ps.at(0).toElement();
 QDomNodeList dn=prop.elementsByTagNameNS("DAV:","displayname"),ct=prop.elementsByTagNameNS("DAV:","getcontenttype");
 QString name=dn.isEmpty()?QFileInfo(resolved.path()).fileName():dn.at(0).toElement().text();
 bool folder=!prop.elementsByTagNameNS("DAV:","collection").isEmpty();QString mime=ct.isEmpty()?QString():ct.at(0).toElement().text();
 QVariantMap item;item["name"]=name;item["url"]=resolved.toString();item["isFolder"]=folder;item["mime"]=mime;item["isImage"]=mime.startsWith("image/");list.append(item);
 }
 m_entries=list;emit entriesChanged();setError(QString());rep->deleteLater();
 });
}
void DavClient::download(const QString&url,const QString&user,const QString&pass,const QString&name){
 QNetworkReply *rep=m_net.get(request(QUrl(url),user,pass));
 connect(rep,&QNetworkReply::finished,this,[this,rep,name](){
 QByteArray data=rep->readAll();if(rep->error()!=QNetworkReply::NoError){setError("Pobieranie nie powiodło się: "+rep->errorString());rep->deleteLater();return;}
 QString dir=QStandardPaths::writableLocation(QStandardPaths::CacheLocation);QDir().mkpath(dir);
 QString safe=QFileInfo(name).fileName();safe.replace(QRegularExpression("[^A-Za-z0-9._-]"),"_");if(safe.isEmpty())safe="murena-file";
 QFile f(dir+"/"+safe);if(!f.open(QIODevice::WriteOnly)||f.write(data)!=data.size()){setError("Nie można zapisać pliku w pamięci podręcznej.");rep->deleteLater();return;}f.close();
 emit downloaded(QUrl::fromLocalFile(f.fileName()).toString(),rep->header(QNetworkRequest::ContentTypeHeader).toString(),safe);setError(QString());rep->deleteLater();
 });
}