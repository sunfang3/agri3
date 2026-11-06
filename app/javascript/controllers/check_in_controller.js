import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["latitude", "longitude", "status"]

  locate() {
    if (!navigator.geolocation) {
      this.statusTarget.textContent = "当前浏览器不支持定位，请填写坐标。"
      return
    }
    this.statusTarget.textContent = "正在获取位置…"
    navigator.geolocation.getCurrentPosition(({ coords }) => {
      this.latitudeTarget.value = coords.latitude
      this.longitudeTarget.value = coords.longitude
      this.statusTarget.textContent = "位置已获取，请确认后提交签到。"
    }, () => {
      this.statusTarget.textContent = "无法获取位置，请允许定位权限或手动填写坐标。"
    }, { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 })
  }
}
