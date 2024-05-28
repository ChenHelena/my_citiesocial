import { Controller } from "stimulus"
import Rails from "@rails/ujs"

export default class extends Controller {
  static targets = [ "email" ]

  addSubscribe(e){
    e.preventDefault();

    let data = new FormData()
    let email = this.emailTarget.value.trim()
    data.append("subscribe[email]", email)

    Rails.ajax({
      url:'/api/v1/subscribe',
      type:'POST',
      dataType: 'json',
      data: data, 
      success: (res) => {
        switch(res.status){
          case 'ok':
           alert('完成訂閱');
           this.emailTarget.value = ''
           break
          case 'duplicate':
           alert(`${res.email}已經訂閱過`);
           break
        }
      }, 
      error: (err) => {
        console.log(err);
      }
    })
  }
}