import QtQuick
import QtQuick.Controls

Dialog {
    id: dialog
    title: qsTr("Ошибка")
    modal: true
    standardButtons: Dialog.Ok

    property string message: ""

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 300

    Label {
        text: message
        wrapMode: Text.WordWrap
        width: parent.width
    }
}
