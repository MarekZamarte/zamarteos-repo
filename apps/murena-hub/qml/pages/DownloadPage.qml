import QtQuick 2.0
import Sailfish.Silica 1.0
Page{id:page;property string fileName:"";property string localUrl:""
 SilicaFlickable{anchors.fill:parent;contentHeight:col.height;Column{id:col;width:parent.width;PageHeader{title:"Pobrano plik"}
 Label{x:Theme.horizontalPageMargin;width:parent.width-2*x;wrapMode:Text.WordWrap;text:page.fileName+"\n\nZapisano w pamięci podręcznej aplikacji."}
 Label{x:Theme.horizontalPageMargin;width:parent.width-2*x;wrapMode:Text.WrapAnywhere;font.pixelSize:Theme.fontSizeSmall;color:Theme.secondaryColor;text:page.localUrl}}}}