import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
Page {
    id: page
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: pageColumn.height
        interactive: false
        Column {
            id: pageColumn
            width: parent.width
            spacing: 0
            PageHeader { title: "Murena Workspace"; description: webView.loading ? "Ładowanie…" : webView.title }
            WebView {
                id: webView
                width: page.width
                height: page.height - Theme.itemSizeMedium
                url: "https://murena.io"
                active: true
                privateMode: false
            }
        }
    }
    DockedPanel {
        dock: Dock.Bottom
        height: Theme.itemSizeMedium
        open: true
        Row {
            anchors.fill: parent
            spacing: Theme.paddingSmall
            IconButton { icon.source: "image://theme/icon-m-back"; enabled: webView.canGoBack; onClicked: webView.goBack() }
            IconButton { icon.source: "image://theme/icon-m-refresh"; onClicked: webView.reload() }
            IconButton { icon.source: "image://theme/icon-m-forward"; enabled: webView.canGoForward; onClicked: webView.goForward() }
            Button {
                width: parent.width - 3*Theme.itemSizeMedium - 3*Theme.paddingSmall
                text: "Panel Murena"
                onClicked: webView.url = "https://murena.io"
            }
        }
    }
}
