import {Controller} from "@hotwired/stimulus"
import Sortable from "sortablejs";
import {patch} from "@rails/request.js";

export default class extends Controller {
    connect() {
        this.sortable = Sortable.create(this.element, {
            onEnd: this.end.bind(this)
        })
    }

    end(event) {
        let id = event.item.dataset.id
        let data = new FormData()
        data.append("position", event.newIndex + 1)

        const plainFormData = Object.fromEntries(data.entries());
        const formDataJsonString = JSON.stringify(plainFormData);

        fetch(this.data.get("url").replace(":id", id), {
            headers: {
                "Content-Type": "application/json",
                "Accept": "application/json"
            },
            method: "PATCH",
            body: formDataJsonString,
        })
    }
}
