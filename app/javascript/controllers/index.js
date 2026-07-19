// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import ReactiveController from "phlex/reactive/reactive_controller"
application.register("reactive", ReactiveController)
import { eagerLoadControllersFrom, lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
lazyLoadControllersFrom("phlex_forms/controllers", application)
eagerLoadControllersFrom("controllers", application)
