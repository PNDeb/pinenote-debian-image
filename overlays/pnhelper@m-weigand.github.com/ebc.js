// rockchip-ebc functions, mainly communicating with the dbus service for the
// Pinenote
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;

const PinenoteDbusInterface = '<node>\
<interface name="org.pinenote.ebc"> \
    <method name="TriggerGlobalRefresh"> \
        <arg name="name" type="s" direction="in"/> \
        <arg name="reply" type="s" direction="out"/> \
    </method> \
</interface> \
</node>';

const PinenoteDbusProxy = Gio.DBusProxy.makeProxyWrapper(PinenoteDbusInterface);

let PnProxy = new PinenoteDbusProxy(
    Gio.DBus.system,
    "org.pinenote.ebc",
    "/",
);

function ebc_trigger_global_refresh(){
	print("Triggering global ebc refresh ");
	print(PnProxy.TriggerGlobalRefreshSync("asd"));
}
