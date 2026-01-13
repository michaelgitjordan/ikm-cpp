cmake_minimum_required(VERSION 3.16)
project(ToDoManager VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Sql)

qt_standard_project_setup()

qt_add_executable(appTodoer
    main.cpp
    databasemanager.h
    databasemanager.cpp
    taskmodel.h
    taskmodel.cpp
)

qt_add_qml_module(appTodoer
    URI ToDoManager
    VERSION 1.0
    QML_FILES
        Main.qml
        TaskCard.qml
        AddTaskDialog.qml
        EditTaskDialog.qml
    RESOURCE_PREFIX /
)

set_target_properties(appTodoer PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.todomanager.app
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appTodoer
    PRIVATE Qt6::Quick Qt6::Sql
)

install(TARGETS appTodoer
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
