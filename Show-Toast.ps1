param(
    $Message,
    $AppUserModelId);

$myPath = (Split-Path -Parent ($MyInvocation.MyCommand.Path));
$myWindowPid = $pid;
while ($myWindowPid -gt 0 -and (Get-Process -id $myWindowPid).MainWindowHandle -eq 0) {
    $myWindowPid = (gwmi Win32_Process -filter "processid = $($myWindowPid)" | select ParentProcessId).ParentProcessId;
}

[void][Windows.Data.Xml.Dom.XmlDocument,Windows.Data.Xml,ContentType=WindowsRuntime];
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument;
[void]($xml.LoadXml('<toast><visual><binding template="ToastText01"><text id="1">' + $Message + '</text></binding></visual></toast>'));

[void][Windows.UI.Notifications.ToastNotification,Windows.UI.Notifications,ContentType=WindowsRuntime];
$toast = New-Object Windows.UI.Notifications.ToastNotification -ArgumentList $xml;

[void][Windows.UI.Notifications.ToastNotificationManager,Windows.UI.Notifications,ContentType=WindowsRuntime];
$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppUserModelId);

Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class PInvoke {
        [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hwnd);
    }
"@

function WrapToastEvent {
    param($target, $eventName);

    Add-Type -Path (Join-Path $myPath "PoshWinRT.dll")
    $wrapper = new-object "PoshWinRT.EventWrapper[Windows.UI.Notifications.ToastNotification,System.Object]";
    $wrapper.Register($target, $eventName);
}

[void](Register-ObjectEvent -InputObject (WrapToastEvent $toast "Activated") -EventName FireEvent -Action { 
    [PInvoke]::SetForegroundWindow((Get-Process -id $myWindowPid).MainWindowHandle);
});
[void]($notifier.show($toast));
