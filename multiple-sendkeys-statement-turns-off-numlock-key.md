title: 使用多个SendKeys语句关闭NumLock的BUG
date: 2015-10-15 19:25:51
categories:
  - Other
tags:
  - VB
toc: true
---

原文地址&emsp;[BUG: Multiple SendKeys Statement Turns Off NumLock Key](https://support.microsoft.com/en-us/kb/179987)

##### 症状

---

&emsp;&emsp;连续执行两个或以上`SendKeys`时会关闭`NumLock`.这个问题也会影响到`CapsLock`和`ScrollLock`。

##### 起因

---

&emsp;&emsp;这个问题涉及到嵌套获取键盘状态。第一个`SendKeys`语句执行时，会获取键盘状态的快照并关闭所有的功能切换。第二个`SendKeys`语句执行前，第一个语句输出所有的按键并恢复键盘状态。这个时候，键盘状态被第二个`SendKeys`再次记录，这个时候所有的切换状态仍然是关闭的。最终，键盘会恢复到最后一次记录（切换关闭）的状态。

##### 分析

---
要解决此问题，请执行下列操作之一：

* 在单个`SendKeys`语句中发送所有的字符。
* 在每个`SendKeys`语句间增加`DoEvents`。然而，根据不同按键的复杂性，这个方法不能在所有情况下起作用。
* 判断使用`SendKeys`前`NumLocks`的设置状态。然后，在使用`SendKeys`前关闭`NumLocks`。使用`SendKeys`之后，恢复`NumLocks`的设置状态。这个可以通过使用`GetKeyboardState` `keybd_event` 还有 `SetKeyboardState` API 函数实现。请参阅下面的参考部分的详细信息
* 使用API函数代替的SendKeys。请参阅下面的参考部分的详细信息

<!-- more -->

##### 现状

---
&emsp;&emsp;在本文开头Microsoft已经确认这是产品中的BUG。我们正在研究这个BUG，并将在Microsoft知识库中发布新信息使其变得可用。

##### 更多信息

---
###### 重现问题的步骤
1. 在Visual Basic中创建一个新的EXE项目。Form1是默认创建的。
2. 为Form1添加一个按钮。
3. 将下面代码复制到Form1的代码窗口。
```
Option Explicit

      Private Sub Command1_Click()
         SendKeys "a"
         SendKeys "b"
      End Sub
```
1. 在运行菜单上单击开始，或按F5键启动该程序。如果NumLock灯亮是关闭状态，按下NumLock键打开NumLock灯。单击按钮并注意NumLock灯状态。
1. 关闭Visual Basic，并重复上述步骤;这次加入的DoEvents ，如下：
```
      Private Sub Command1_Click()
         SendKeys "a"
         DoEvents
         SendKeys "b"
      End Sub
```
注意：在尝试DoEvents方案前你需要重启Visual Basic。否则键盘状态可能会被设置错误，妨碍了其他成功的解决方案尝试。

##### 参考

---
"Visual Basic 5.0 Win32 API 程序员指南",作者：Dan Appleman，第六章：硬件和系统函数

有关更多信息，请参阅Microsoft知识库中的以下文章：
[177674](https://support.microsoft.com/en-us/kb/177674) 如何：切换NUM  LOCK，CAPS LOCK和Scroll Lock键

#### Properties

---
Article ID: 179987 - Last Review: 06/22/2014 18:46:00 - Revision: 5.0
 
Applies to
Microsoft Visual Basic 4.0 Standard Edition
Microsoft Visual Basic 4.0 Professional Edition
Microsoft Visual Basic 5.0 Learning Edition
Microsoft Visual Basic 5.0 Professional Edition
Microsoft Visual Basic 5.0 Enterprise Edition
Keywords:
kbbug kbpending kbprogramming KB179987

#####另一个解决方案

---
**原贴 [SendKeys turn off the NumLock, Capslock, & etc](http://www.vbforums.com/showthread.php?48761-SendKeys-turning-off-NumLock-and-CapsLock)**

>**OhYeahLach:**

>When using the following code, the NumLock, CapsLock, and Scroll gets Turn off.
AppActivate IDIdentifier, False
```
'Send a Ctrl-A (Select All) and Ctrl-Ins (Copy)
SendKeys "^a"
SendKeys "^{INSERT}"
```
>I would like to prevent this from happening. My alternate solution was to turn the keys on through the key_bd_event. 

>However it only worked in step mode. Any ideas?
```
Private Declare Function GetKeyboardState Lib "user32" (pbKeyState As Byte) As Long
Public Declare Sub keybd_event Lib "user32.dll" (ByVal bVk As Byte, ByVal bScan As Byte, ByVal dwFlags As Long, ByVal dwExtraInfo As Long)

Public Const VK_NUMLOCK = &H90
Public Const KEYEVENTF_KEYUP = &H2
Public Const VK_Capital = &H14


Dim AllKeys(255) As Byte
Dim NumLock As Byte
Dim retVal As Long
retVal = GetKeyboardState(AllKeys(0))
NumLock = AllKeys(VK_NUMLOCK)

'Set focus to ID ToolTip
AppActivate IDIdentifier, False
'Send a Ctrl-A (Select All) and Ctrl-Ins (Copy)
SendKeys "^a"
SendKeys "^{INSERT}"

DoEvents
If NumLock = 1 Then
keybd_event VK_NUMLOCK, 0, 0, 0
keybd_event VK_NUMLOCK, 0, KEYEVENTF_KEYUP, 0
MsgBox NumLock

End If
```
>**Frans C:**

>Instead of turning numlock back on, you could avoid using SendKeys at all. Turning numlock off is a known bug in SendKeys. You could use the key_bd_event to press the Ctrl-A and Ctrl-Ins.

>eg
Code:
```
Option Explicit
Private Const VK_CONTROL = &H11
Private Const VK_INSERT = &H2D
Private Const VK_NUMLOCK = &H90
Private Const KEYEVENTF_KEYUP = &H2

Private Declare Function VkKeyScan Lib "user32" Alias "VkKeyScanA" (ByVal cChar As Byte) As Integer
Private Declare Sub keybd_event Lib "user32.dll" (ByVal bVk As Byte, ByVal bScan As Byte, ByVal dwFlags As Long, ByVal dwExtraInfo As Long)

Private Sub Command1_Click()
Dim retVal As Long
Dim VK_A As Integer

    AppActivate "Untitled - Notepad"
    'DoEvents
    ' find the Virtual key code for char A
    VK_A = VkKeyScan(Asc("a"))
    ' send  CTRL-A
    ' press CTRL down
    keybd_event VK_CONTROL, 0, 0, 0
    ' press A down
    keybd_event VK_A, 0, 0, 0
    ' release the A key
    keybd_event VK_A, 0, KEYEVENTF_KEYUP, 0
    ' release CTRL key
    keybd_event VK_CONTROL, 0, KEYEVENTF_KEYUP, 0

    ' send  CTRL-INS
    ' press CTRL down
    keybd_event VK_CONTROL, 0, 0, 0
    ' press INS down
    keybd_event VK_INSERT, 0, 0, 0
    ' release the INS key
    keybd_event VK_INSERT, 0, KEYEVENTF_KEYUP, 0
    ' release CTRL key
    keybd_event VK_CONTROL, 0, KEYEVENTF_KEYUP, 0

End Sub
```

>参考资料
>&emsp;[Virtual-Key Codes](https://msdn.microsoft.com/en-us/library/dd375731%28v=vs.85%29.aspx)
