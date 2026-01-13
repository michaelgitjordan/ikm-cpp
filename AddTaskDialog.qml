import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: addDialog
    title: "Добавить новую задачу"
    anchors.centerIn: parent
    modal: true
    width: 500
    height: 550

    property var selectedTags: []

    onOpened: {
        titleField.text = ""
        descriptionField.text = ""
        dueDateField.text = ""
        priorityCombo.currentIndex = 0
        statusCombo.currentIndex = 0
        selectedTags = []
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Label {
            text: "Заголовок *"
            font.bold: true
        }
        TextField {
            id: titleField
            Layout.fillWidth: true
            placeholderText: "Введите название задачи"
        }

        Label {
            text: "Описание"
            font.bold: true
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 100

            TextArea {
                id: descriptionField
                placeholderText: "Введите описание задачи"
                wrapMode: TextArea.Wrap
            }
        }

        Label {
            text: "Срок выполнения"
            font.bold: true
        }
        TextField {
            id: dueDateField
            Layout.fillWidth: true
            placeholderText: "ГГГГ-ММ-ДДTЧЧ:ММ (например: 2025-01-20T15:00)"
        }

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true

                Label {
                    text: "Приоритет *"
                    font.bold: true
                }
                ComboBox {
                    id: priorityCombo
                    Layout.fillWidth: true
                    model: ["Низкий", "Средний", "Высокий"]
                    currentIndex: 0
                }
            }

            ColumnLayout {
                Layout.fillWidth: true

                Label {
                    text: "Статус *"
                    font.bold: true
                }
                ComboBox {
                    id: statusCombo
                    Layout.fillWidth: true
                    model: taskModel.statuses
                    textRole: "status_name"
                    currentIndex: 0
                }
            }
        }

        Label {
            text: "Теги"
            font.bold: true
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            Flow {
                width: parent.width
                spacing: 5

                Repeater {
                    model: taskModel.tags

                    Rectangle {
                        width: tagLabel.width + 24
                        height: 28
                        radius: 14
                        color: isSelected ? modelData.color : "#f0f0f0"
                        border.color: modelData.color
                        border.width: 2

                        property bool isSelected: selectedTags.indexOf(modelData.tag_id) >= 0

                        Label {
                            id: tagLabel
                            anchors.centerIn: parent
                            text: modelData.tag_name
                            color: parent.isSelected ? "white" : "#333"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var index = selectedTags.indexOf(modelData.tag_id)
                                if (index >= 0) {
                                    selectedTags.splice(index, 1)
                                } else {
                                    selectedTags.push(modelData.tag_id)
                                }
                                selectedTags = selectedTags.slice()
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        if (titleField.text.trim() === "") {
            return
        }

        var userId = taskModel.users[userCombo.currentIndex].user_id
        var priority = priorityCombo.currentIndex + 1
        var statusId = taskModel.statuses[statusCombo.currentIndex].status_id

        var success = dbManager.addTask(
            userId,
            titleField.text,
            descriptionField.text,
            dueDateField.text,
            priority,
            statusId
        )

        if (success && selectedTags.length > 0) {
            var tasks = dbManager.getAllTasks(userId)
            if (tasks.length > 0) {
                var lastTaskId = tasks[0].task_id
                for (var i = 0; i < selectedTags.length; i++) {
                    dbManager.addTagToTask(lastTaskId, selectedTags[i])
                }
            }
        }
    }
}
