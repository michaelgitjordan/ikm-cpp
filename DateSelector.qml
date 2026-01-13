import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: popup
    width: 300
    height: 350
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    signal dateSelected(date selectedDate)

    property date currentDate: new Date()

    function openWithDate(date) {
        daySpinBox.value = date.getDate()
        monthSpinBox.value = date.getMonth() + 1
        yearSpinBox.value = date.getFullYear()
        popup.open()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Label {
            text: qsTr("Выберите дату")
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        GridLayout {
            columns: 3
            Layout.alignment: Qt.AlignHCenter

            Label { text: qsTr("День:") }
            SpinBox {
                id: daySpinBox
                from: 1
                to: 31
                value: new Date().getDate()
            }

            Label { text: qsTr("Месяц:") }
            SpinBox {
                id: monthSpinBox
                from: 1
                to: 12
                value: new Date().getMonth() + 1
            }

            Label { text: qsTr("Год:") }
            SpinBox {
                id: yearSpinBox
                from: 2000
                to: 2100
                value: new Date().getFullYear()
            }
        }

        Label {
            text: qsTr("Выбранная дата: ") +
                  daySpinBox.value.toString().padStart(2, '0') + "." +
                  monthSpinBox.value.toString().padStart(2, '0') + "." +
                  yearSpinBox.value
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10

            Button {
                text: qsTr("Сегодня")
                onClicked: {
                    var today = new Date()
                    daySpinBox.value = today.getDate()
                    monthSpinBox.value = today.getMonth() + 1
                    yearSpinBox.value = today.getFullYear()
                }
            }

            Button {
                text: qsTr("Отмена")
                onClicked: popup.close()
            }

            Button {
                text: qsTr("Выбрать")
                highlighted: true
                onClicked: {
                    var selectedDate = new Date(yearSpinBox.value,
                                                monthSpinBox.value - 1,
                                                daySpinBox.value)
                    popup.dateSelected(selectedDate)
                    popup.close()
                }
            }
        }
    }
}
