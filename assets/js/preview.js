import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import { hooks } from "./app"

const token = document.querySelector("meta[name='csrf-token']").content
const liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: token }, hooks })
liveSocket.connect()
window.liveSocket = liveSocket
