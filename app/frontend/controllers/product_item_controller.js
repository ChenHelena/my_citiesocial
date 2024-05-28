import { Controller } from "stimulus"
import Rails from "@rails/ujs"

export default class extends Controller {
  static targets = [ "quantity", "sku", "addToCartButton", "cartTotal", "subtotal" ]


  
  addToCart(e){
    e.preventDefault();

    let product_id = this.data.get("id")
    let sku = this.skuTarget.value
    let quantity = this.quantityTarget.value

    if(quantity > 0){ 
      this.addToCartButtonTarget.classList.remove("is-hidden")
      this.addToCartButtonTarget.classList.add("is-loading")

      let data = new FormData()
      data.append("id", product_id)
      data.append("sku", sku)
      data.append("quantity", quantity)

      Rails.ajax({
        url:'/api/v1/cart',
        type: 'POST',
        data,
        success: res => {
          if(res.status === 'ok'){
            let item_count = res.items || 0
            let evt = new CustomEvent('addToCart', { 'detail': { item_count } })
            document.dispatchEvent(evt)
          }
          console.log(res);
        },
        err: err => {
          console.log(err);
        },
        complete: () => {
          setTimeout(() => {
            this.addToCartButtonTarget.classList.add("is-hidden")
            this.addToCartButtonTarget.classList.remove("is-loading")
          }, 300)
        }
      })

    }
  } 

  quantity_minus(e){
    e.preventDefault();
    let quantity = Number(this.quantityTarget.value)
    if (quantity > 1){
      this.quantityTarget.value = quantity 
      this.updateQuantity(quantity - 1)
      this.updateCartItemQuantity(quantity - 1);
    }
  }

  quantity_plus(e){
    e.preventDefault();
    let quantity = Number(this.quantityTarget.value)
    this.quantityTarget.value = quantity
    this.updateQuantity(quantity + 1)
    this.updateCartItemQuantity(quantity + 1);
  }

  updateQuantity(quantity){
    this.quantityTarget.value = quantity
    if(this.element.closest('[data-cart-page]')){
      this.updateCartItemQuantity(quantity)
    }
 
  }

  updateCartItemQuantity(quantity){
    let sku = this.data.get("id")
    let data = new FormData()
    data.append("quantity", quantity)
    data.append("sku", sku)

    Rails.ajax({
      url: `/api/v1/cart/${sku}`,
      type: 'PATCH',
      data,
      success: res => {
        if(res.status === 'ok'){
          
          console.log(this.subtotalTarget);
          this.subtotalTarget.innerHTML = `NT ${res.updated_total_price}` 

          let evt = new CustomEvent('cartTotalUpdated', { 'detail': { updatedCartTotal: res.updated_cart_total } })
          document.dispatchEvent(evt)
          console.log('Quantity updated successfully:', res)
        }
      },
      error: err => {
        console.log('Error updated quantity:', err);
      }
    })
  }

}