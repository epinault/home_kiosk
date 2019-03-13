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
import { Socket } from "phoenix";
import css from "../css/app.css";

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"
let socket = new Socket("/socket", {
  logger: (kind, msg, data) => {
    console.log(`${kind}: ${msg}`, data);
  }
});

var chan = socket.channel("rooms:lobby", {});
var weather = $(".weather");
var $messages = $("#messages");
var $input = $("#message-input");
var $username = $("#username");
var brightnessSlider = document.getElementById("brightnessRange");

class App {
  static init() {
    socket.connect({ user_id: "123" });
    socket.onOpen(ev => console.log("OPEN", ev));
    socket.onError(ev => console.log("ERROR", ev));
    socket.onClose(e => console.log("CLOSE", e));

    chan
      .join()
      .receive("ignore", () => console.log("auth error"))
      .receive("ok", () => console.log("join ok"));
    // .after(10000, () => console.log("Connection interruption"))
    chan.onError(e => console.log("something went wrong", e));
    chan.onClose(e => console.log("channel closed", e));

    weather.click(() => {
      chan.push("weather:update", { color: "blue" });
    });

    chan.on("weather:update", msg => {
      console.log(msg);
      weather.empty();
      weather.append(msg.msg);
    });

    chan.on("brightness", payload => {
      if (brightnessSlider) {
        brightnessSlider.value = payload.value;
      }
    });

    if (brightnessSlider) {
      brightnessSlider.oninput = function() {
        chan.push("brightness", { value: parseInt(this.value) });
        console.log("Brightness:" + this.value);
      };
    }

    chan.on("user:entered", msg => {
      var username = this.sanitize(msg.user || "anonymous");
      $messages.append(`<br/><i>[${username} entered]</i>`);
    });

    var mc = new Hammer(document);

    // listen to events...
    mc.on("doubletap", function(ev) {
      chan.push("brightness", { value: 50 });
    });
  }

  static poweroff() {
    chan.push("brightness", { value: 1 });
  }
}

$(() => {
  return App.init();
});

window.app = App;
export default App;
