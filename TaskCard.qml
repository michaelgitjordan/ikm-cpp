import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: taskCard
    height: cardContent.height + 20
    radius: 8
    border.color: "#e0e0e0"
    border.width: 1
    color: "white"

    property var taskData
    signal editClicked()
    signal deleteClicked()
    signal completeClicked()

    function getPriorityColor(priority) {
        switch(priority) {
            case 3: return "#F44336" // Высокий - красный
            case 2: return "#FF9800" // Средний - оранжевый
            case 1: return "#4CAF50" // Низкий - зеленый
            default: return "#9E9E9E"
        }
    }

    function getPriorityText(priority) {
        switch(priority) {
            case 3: return "Высокий"
            case 2: return "Средний"
            case 1: return "Низкий"
            default: return "Не указан"
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
    }

    states: [
        State {
            when: hoverArea.containsMouse
            PropertyChanges {
                target: taskCard
                border.color: "#2196F3"
                border.width: 2
            }
        }
    ]

    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Заголовок и кнопки
        RowLayout {
            Layout.fillWidth: true

            // Приоритет
            Rectangle {
                width: 8
                height: 40
                radius: 4
                color: getPriorityColor(taskData.priority)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: taskData.title
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: " " + taskData.user_name
                    font.pixelSize: 12
                    color: "#666"
                }
            }

            // Статус
            Rectangle {
                width: statusLabel.width + 16
                height: 24
                radius: 12
                color: {
                    switch(taskData.status_id) {
                        case 1: return "#4CAF50" // active
                        case 2: return "#2196F3" // completed
                        case 3: return "#FF9800" // cancelled
                        default: return "#9E9E9E"
                    }
                }

                Label {
                    id: statusLabel
                    anchors.centerIn: parent
                    text: taskData.status_name
                    color: "white"
                    font.pixelSize: 11
                }
            }
        }

        // Описание
        Label {
            visible: taskData.description && taskData.description.length > 0
            text: taskData.description
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: "#555"
            font.pixelSize: 13
        }

        // Теги
        Flow {
            Layout.fillWidth: true
            spacing: 5
            visible: taskData.tags && taskData.tags.length > 0

            Repeater {
                model: taskData.tags || []

                Rectangle {
                    width: tagText.width + 12
                    height: 22
                    radius: 11
                    color: modelData.color || "#cccccc"

                    Label {
                        id: tagText
                        anchors.centerIn: parent
                        text: " " + modelData.tag_name
                        color: "white"
                        font.pixelSize: 11
                    }
                }
            }
        }

        // Информация о датах
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 4
            columnSpacing: 10

            Label {
                text: "Создана:"
                font.pixelSize: 11
                color: "#666"
            }
            Label {
                text: taskData.created_at
                font.pixelSize: 11
            }

            Label {
                visible: taskData.due_at && taskData.due_at.length > 0
                text: "Срок:"
                font.pixelSize: 11
                color: "#666"
            }
            Label {
                visible: taskData.due_at && taskData.due_at.length > 0
                text: taskData.due_at
                font.pixelSize: 11
                color: "#F44336"
                font.bold: true
            }

            Label {
                visible: taskData.completed_at && taskData.completed_at.length > 0
                text: "Завершена:"
                font.pixelSize: 11
                color: "#666"
            }
            Label {
                visible: taskData.completed_at && taskData.completed_at.length > 0
                text: taskData.completed_at
                font.pixelSize: 11
                color: "#4CAF50"
            }

            Label {
                text: "Приоритет:"
                font.pixelSize: 11
                color: "#666"
            }
            Label {
                text: getPriorityText(taskData.priority)
                font.pixelSize: 11
                color: getPriorityColor(taskData.priority)
                font.bold: true
            }
        }

        // Кнопки действий
        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Button {
                text: "Изменить"
                onClicked: editClicked()
                Layout.preferredWidth: 100
            }

            Button {
                text: "Завершить"
                onClicked: completeClicked()
                enabled: taskData.status_id === 1
                Layout.preferredWidth: 110
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Удалить"
                onClicked: deleteClicked()
                Layout.preferredWidth: 100
                palette.button: "#ffebee"
            }
        }
    }
}
