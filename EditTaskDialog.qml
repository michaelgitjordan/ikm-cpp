import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: editDialog
    title: "Редактировать задачу"
    anchors.centerIn: parent
    modal: true
    width: 500
    height: 550

    property var currentTask: null
    property var selectedTags: []

    function loadTask(task) {
        currentTask = task
        titleField.text = task.title
        descriptionField.text = task.description || ""
        dueDateField.text = task.due_at || ""
        priorityCombo.currentIndex = task.priority - 1

        for (var i = 0; i < taskModel.statuses.length; i++) {
            if (taskModel.statuses[i].status_id === task.status_id) {
                statusCombo.currentIndex = i
                break
            }
        }

        selectedTags = []
        if (task.tags) {
            for (var j = 0; j < task.tags.length; j++) {
                selectedTags.push(task.tags[j].tag_id)
            }
        }
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
        if (!currentTask || titleField.text.trim() === "") {
            return
        }

        var priority = priorityCombo.currentIndex + 1
        var statusId = taskModel.statuses[statusCombo.currentIndex].status_id

        var success = dbManager.updateTask(
            currentTask.task_id,
            titleField.text,
            descriptionField.text,
            dueDateField.text,
            priority,
            statusId
        )

        if (success) {
            var existingTags = currentTask.tags || []

            for (var i = 0; i < existingTags.length; i++) {
                if (selectedTags.indexOf(existingTags[i].tag_id) < 0) {
                    dbManager.removeTagFromTask(currentTask.task_id, existingTags[i].tag_id)
                }
            }

            for (var j = 0; j < selectedTags.length; j++) {
                var tagExists = false
                for (var k = 0; k < existingTags.length; k++) {
                    if (existingTags[k].tag_id === selectedTags[j]) {
                        tagExists = true
                        break
                    }
                }
                if (!tagExists) {
                    dbManager.addTagToTask(currentTask.task_id, selectedTags[j])
                }
            }
        }
    }
}
