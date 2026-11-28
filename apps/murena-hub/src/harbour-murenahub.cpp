#include <sailfishapp.h>
#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include "davclient.h"
int main(int argc,char *argv[]){
 QScopedPointer<QGuiApplication> app(SailfishApp::application(argc,argv));
 QScopedPointer<QQuickView> view(SailfishApp::createView());
 DavClient client;view->rootContext()->setContextProperty("davClient",&client);
 view->setSource(SailfishApp::pathTo("qml/harbour-murenahub.qml"));view->show();return app->exec();
}