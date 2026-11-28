import QtQuick 2.0
import Sailfish.Silica 1.0
Page{property string imageUrl:"";property string imageName:""
 SilicaFlickable{anchors.fill:parent;contentHeight:col.height;Column{id:col;width:parent.width;PageHeader{title:page.imageName}
 Image{width:parent.width;height:page.height-Theme.itemSizeLarge;source:page.imageUrl;fillMode:Image.PreserveAspectFit;asynchronous:true;cache:false}}}}