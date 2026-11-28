import QtQuick 2.0
import Sailfish.Silica 1.0
Page{
 id:page
 property string imageUrl:""
 property string imageName:""
 SilicaFlickable{
  anchors.fill:parent
  contentHeight:column.height
  Column{
   id:column
   width:parent.width
   PageHeader{title:page.imageName}
   Image{
    id:photo
    width:parent.width
    height:Math.max(1,page.height-Theme.itemSizeLarge)
    source:page.imageUrl
    fillMode:Image.PreserveAspectFit
    asynchronous:true
    cache:false
    sourceSize.width:Math.min(width,1600)
    sourceSize.height:Math.min(height,1600)
   }
   Label{
    visible:photo.status===Image.Error
    width:parent.width-2*Theme.horizontalPageMargin
    x:Theme.horizontalPageMargin
    wrapMode:Text.WordWrap
    color:Theme.errorColor
    text:"Nie można wyświetlić zdjęcia: "+page.imageName
   }
  }
 }
}