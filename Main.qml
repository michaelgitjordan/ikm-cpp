import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 1200
    height: 800
    visible: true
    title: "ToDoManager - Менеджер задач"

    property var selectedTask: null
    property bool isConnected: false

    Component.onCompleted: {
        checkConnection()
    }

    function checkConnection() {
        isConnected = dbManager.isConnected()
        if (isConnected) {
            statusBar.text = "Подключено к базе данных"
            statusBar.color = "#4CAF50"
        } else {
            statusBar.text = "Ошибка подключения к базе данных"
            statusBar.color = "#F44336"
        }
    }

    function refreshData() {
        taskModel.refreshAll()
    }

    header: ToolBar {
        background: Rectangle {
            color: "#3e3e95"
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 1

            Label {
                text: "ToDoManager"
                font.pixelSize: 25
                font.bold: true
                color: "white"
            }

            Item { Layout.fillWidth: true }

            ComboBox {
                id: userCombo
                Layout.preferredWidth: 200
                model: taskModel.users
                textRole: "name"
                displayText: currentIndex >= 0 ? " " + currentText : "Выберите пользователя"

                onCurrentIndexChanged: {
                    if (currentIndex >= 0) {
                        var userId = taskModel.users[currentIndex].user_id
                        taskModel.currentUserId = userId
                    }
                }
            }

            Button {
                text: "Обновить"
                onClicked: refreshData()
            }

            Button {
                text: "Задача"
                onClicked: addTaskDialog.open()
                // enabled: isConnected && userCombo.currentIndex >= 0
            }
        }
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // Левая панель - фильтры и статистика
        Rectangle {
            SplitView.preferredWidth: 250
            SplitView.minimumWidth: 200
            color: "#f5f5f5"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 15

                // Статистика
                GroupBox {
                    Layout.fillWidth: true
                    title: "Статистика"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            color: "#4CAF50"
                            radius: 5

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8

                                Label {
                                    text: "Активные"
                                    color: "white"
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: taskModel.statistics.active || 0
                                    color: "white"
                                    font.bold: true
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            color: "#2196F3"
                            radius: 5

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8

                                Label {
                                    text: "Завершенные"
                                    color: "white"
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: taskModel.statistics.completed || 0
                                    color: "white"
                                    font.bold: true
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            color: "#FF9800"
                            radius: 5

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8

                                Label {
                                    text: "Всего"
                                    color: "white"
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: taskModel.statistics.total || 0
                                    color: "white"
                                    font.bold: true
                                }
                            }
                        }
                    }
                }

                // Фильтры по статусу
                GroupBox {
                    Layout.fillWidth: true
                    title: "Фильтр по статусу"

                    ColumnLayout {
                        anchors.fill: parent

                        Repeater {
                            model: taskModel.statuses

                            Button {
                                Layout.fillWidth: true
                                text: modelData.status_name
                                onClicked: {
                                    taskModel.filterByStatus(modelData.status_id)
                                }
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "Все задачи"
                            highlighted: true
                            onClicked: taskModel.clearFilters()
                        }
                    }
                }

                // Теги
                GroupBox {
                    Layout.fillWidth: true
                    title: "Теги"

                    ScrollView {
                        anchors.fill: parent
                        clip: true

                        Flow {
                            width: parent.width
                            spacing: 5

                            Repeater {
                                model: taskModel.tags

                                Rectangle {
                                    width: tagLabel.width + 16
                                    height: 28
                                    color: modelData.color || "#cccccc"
                                    radius: 14

                                    Label {
                                        id: tagLabel
                                        anchors.centerIn: parent
                                        text: modelData.tag_name
                                        color: "white"
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            taskModel.filterByTag(modelData.tag_id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // Центральная область - список задач
        Rectangle {
            SplitView.fillWidth: true
            color: "white"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 50
                    color: "#f5f5f5"
                    border.color: "#e0e0e0"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        Label {
                            text: "Задачи"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: "Всего: " + taskListView.count
                            font.pixelSize: 14
                            color: "#666"
                        }
                    }
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: taskListView
                        model: taskModel.tasks
                        spacing: 150
                        anchors.margins: 10

                        delegate: TaskCard {
                            width: taskListView.width - 20
                            taskData: modelData

                            onEditClicked: {
                                selectedTask = modelData
                                editTaskDialog.loadTask(modelData)
                                editTaskDialog.open()
                            }

                            onDeleteClicked: {
                                deleteDialog.taskId = modelData.task_id
                                deleteDialog.taskTitle = modelData.title
                                deleteDialog.open()
                            }

                            onCompleteClicked: {
                                dbManager.completeTask(modelData.task_id)
                                refreshData()
                            }
                        }

                        Label {
                            visible: taskListView.count === 0
                            anchors.centerIn: parent
                            text: "Нет задач"
                            font.pixelSize: 16
                            color: "#999"
                        }
                    }
                }
            }
        }
    }

    footer: Rectangle {
        height: 30
        color: "#f5f5f5"
        border.color: "#e0e0e0"
        border.width: 1

        Label {
            id: statusBar
            anchors.centerIn: parent
            text: "Готов"
            font.pixelSize: 12
        }
    }

    // Диалог добавления задачи
    AddTaskDialog {
        id: addTaskDialog
        onAccepted: refreshData()
    }

    // Диалог редактирования задачи
    EditTaskDialog {
        id: editTaskDialog
        onAccepted: refreshData()
    }

    // Диалог удаления
    Dialog {
        id: deleteDialog
        title: "Удаление задачи"
        anchors.centerIn: parent
        modal: true

        property var taskId: 0
        property string taskTitle: ""

        ColumnLayout {
            Label {
                text: "Вы действительно хотите удалить задачу?"
                Layout.margins: 10
            }
            Label {
                text: '"' + deleteDialog.taskTitle + '"'
                font.bold: true
                Layout.margins: 10
            }
        }

        standardButtons: Dialog.Yes | Dialog.No

        onAccepted: {
            dbManager.deleteTask(taskId)
            refreshData()
        }
    }

    Connections {
        target: dbManager
        function onErrorOccurred(error) {
            statusBar.text = "Ошибка: " + error
            statusBar.color = "#F44336"
        }
    }
}
