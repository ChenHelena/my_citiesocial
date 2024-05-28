import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "count", "tagContainer" ]

  connect(){
    this.toggleCartTag()
    document.addEventListener('cartTotalUpdated', this.cartTotalUpdated.bind(this))
    // document.addEventListener('subtotalUpdated', this.subtotalUpdated.bind(this))
  }
 
  updateCount(evt){
    let data = evt.detail
    this.countTarget.innerText = `${data.item_count}`
    this.toggleCartTag();
  }

  cartTotalUpdated(evt){
    const cartTotalElement = document.querySelector("[data-product-item-target='cartTotal']");
    if (cartTotalElement) {
      cartTotalElement.innerHTML = `NT ${evt.detail.updatedCartTotal}`;
    }
  }

  subtotalUpdated(event){
    const subtotalElement = document.querySelector("[data-product-item-target='subtotal']");
    if (subtotalElement) {
      subtotalElement.innerHTML = `NT ${event.detail.updatedsubtotal}`;
    }
  }

  toggleCartTag() {
    let itemCount = parseInt(this.countTarget.textContent)
    if(this.tagContainerTarget){
      this.tagContainerTarget.classList.toggle('is-hidden', itemCount <= 0)
    }
  }
}
