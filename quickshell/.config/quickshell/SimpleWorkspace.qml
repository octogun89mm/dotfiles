import QtQuick

Item {
  implicitWidth: workspaceRow.implicitWidth
  implicitHeight: 20

  Row {
    id: workspaceRow
    anchors.verticalCenter: parent.verticalCenter
    spacing: 6

    Repeater {
      model: 10

      SimpleWorkspaceChip {
        required property int index
        workspaceId: index === 9 ? 10 : index + 1
        displayName: String(index === 9 ? 0 : index + 1)
      }
    }
  }
}
