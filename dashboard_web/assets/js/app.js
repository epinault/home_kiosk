// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
// import "phoenix_html"
import { Socket } from "phoenix"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

class App {

    static init() {
        let socket = new Socket("/socket", {
            logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data) })
        })

        socket.connect({ user_id: "123" })
        var $status = $("#status")
        var $messages = $("#messages")
        var $input = $("#message-input")
        var $username = $("#username")

        socket.onOpen(ev => console.log("OPEN", ev))
        socket.onError(ev => console.log("ERROR", ev))
        socket.onClose(e => console.log("CLOSE", e))

        var chan = socket.channel("rooms:lobby", {})
        chan.join().receive("ignore", () => console.log("auth error"))
            .receive("ok", () => console.log("join ok"))
        // .after(10000, () => console.log("Connection interruption"))
        chan.onError(e => console.log("something went wrong", e))
        chan.onClose(e => console.log("channel closed", e))

        $input.off("keypress").on("keypress", e => {
            if (e.keyCode == 13) {
                chan.push("new:msg", { user: $username.val(), body: $input.val() })
                $input.val("")
            }
        })

        chan.on("new:msg", msg => {
            $messages.append(this.messageTemplate(msg))
            scrollTo(0, document.body.scrollHeight)
        })

        chan.on("user:entered", msg => {
            var username = this.sanitize(msg.user || "anonymous")
            $messages.append(`<br/><i>[${username} entered]</i>`)
        })
    }

    static sanitize(html) { return $("<div/>").text(html).html() }

    static messageTemplate(msg) {
        let username = this.sanitize(msg.user || "anonymous")
        let body = this.sanitize(msg.body)

        return (`<p><a href='#'>[${username}]</a>&nbsp; ${body}</p>`)
    }

}

$(() => {
    return App.init();
})

export default App