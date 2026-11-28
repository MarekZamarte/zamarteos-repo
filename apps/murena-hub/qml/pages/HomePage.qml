import QtQuick 2.0
import Sailfish.Silica 1.0
Page{
 id:page
 property string server:"https://murena.io/remote.php/dav/files/"
 property string user:""
 property string password:""
 property string current:""
 property string status:""
 function connectCloud(){var u=server.trim();if(u.charAt(u.length-1)!="/")u+="/";if(u.indexOf("/remote.php/dav/files/")>=0&&u.substring(u.indexOf("/remote.php/dav/files/")+22).length===0)u+=encodeURIComponent(user)+"/";current=u;davClient.list(current,user,password)}
 function upUrl(){var p=current.replace(/\/$/, ""),i=p.lastIndexOf("/");return i>p.indexOf("://")+2?p.substring(0,i+1):server}
 Connections{
  target:davClient
  onDownloaded:{
   var lowerName=name.toLowerCase()
   var lowerMime=mime.toLowerCase()
   var isImage=lowerMime.indexOf("image/")===0||/\.(png|jpe?g|gif|webp|bmp|svg|heic|avif|tif|tiff)$/i.test(lowerName)
   if(isImage)pageStack.push(Qt.resolvedUrl("PhotoPage.qml"),{imageUrl:localUrl,imageName:name})
   else pageStack.push(Qt.resolvedUrl("DownloadPage.qml"),{fileName:name,localUrl:localUrl})
  }
 }
 SilicaFlickable{anchors.fill:parent;contentHeight:col.height;VerticalScrollDecorator{}
  Column{id:col;width:parent.width;spacing:Theme.paddingSmall
   PageHeader{title:"Murena — pliki i zdjęcia"}
   TextField{width:parent.width;label:"Adres WebDAV";text:page.server;inputMethodHints:Qt.ImhUrlCharactersOnly;onTextChanged:page.server=text}
   TextField{width:parent.width;label:"Użytkownik Murena";placeholderText:"nazwa użytkownika lub e-mail";text:page.user;onTextChanged:page.user=text}
   TextField{width:parent.width;label:"Hasło aplikacji";echoMode:TextInput.Password;placeholderText:"hasło aplikacji, nie główne";text:page.password;onTextChanged:page.password=text}
   Button{x:Theme.horizontalPageMargin;width:parent.width-2*x;text:"Połącz i pokaż pliki";onClicked:page.connectCloud()}
   Label{x:Theme.horizontalPageMargin;width:parent.width-2*x;wrapMode:Text.WordWrap;color:davClient.error.length?Theme.errorColor:Theme.secondaryColor;text:davClient.error.length?davClient.error:(page.status||page.current||"Natywne połączenie WebDAV — bez przeglądarki")}
   SectionHeader{text:"Pliki i foldery"}
   BackgroundItem{width:parent.width;height:Theme.itemSizeSmall;visible:page.current.length>0;onClicked:davClient.list(page.upUrl(),page.user,page.password);Label{x:Theme.horizontalPageMargin;anchors.verticalCenter:parent.verticalCenter;text:"↑ Folder nadrzędny";color:Theme.highlightColor}}
   Repeater{model:davClient.entries;delegate:ListItem{width:parent.width;contentHeight:Theme.itemSizeMedium;Label{x:Theme.horizontalPageMargin;anchors.verticalCenter:parent.verticalCenter;width:parent.width-2*x;text:(modelData.isFolder?"[Folder] ":modelData.isImage?"[Zdjęcie] ":"[Plik] ")+modelData.name;truncationMode:TruncationMode.Fade;color:Theme.primaryColor}
    onClicked:{if(modelData.isFolder){page.current=modelData.url;davClient.list(page.current,page.user,page.password)}else davClient.download(modelData.url,page.user,page.password,modelData.name)}
    menu:ContextMenu{MenuItem{text:"Pobierz";onClicked:davClient.download(modelData.url,page.user,page.password,modelData.name)}}}}
   Label{x:Theme.horizontalPageMargin;width:parent.width-2*x;wrapMode:Text.WordWrap;font.pixelSize:Theme.fontSizeSmall;color:Theme.secondaryColor;text:"Zdjęcia otwierają się w natywnym podglądzie. Pliki pobierane są do pamięci podręcznej. Hasło aplikacji jest przechowywane tylko w pamięci podczas działania aplikacji."}
  }
 }
}