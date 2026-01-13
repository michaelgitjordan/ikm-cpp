import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: popup
    width: 300
    height: 400
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    signal dateSelected(date selectedDate)

    property date currentDate: new Date()

    function openWithDate(date) {
        currentDate = date
        calendar.selectedDate = date
        popup.open()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        Calendar {
            id: calendar
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight

            Button {
                text: qsTr("Отмена")
                onClicked: popup.close()
            }

            Button {
                text: qsTr("Выбрать")
                highlighted: true
                onClicked: {
                    popup.dateSelected(calendar.selectedDate)
                    popup.close()
                }
            }
        }
    }
}
