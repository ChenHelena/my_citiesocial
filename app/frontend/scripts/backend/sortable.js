import Sortable from "sortablejs"
import Rails from '@rails/ujs'

document.addEventListener('turbolinks:load', () => {
  let el = document.querySelector('.sortable-items')
  if(el){
    Sortable.create(el, {
      onEnd: e => {
        let [model, id] = e.item.dataset.item.split('_')
        let data = new FormData()
        data.append("id", id)
        data.append("from", e.oldIndex)
        data.append("to", e.newIndex)

        Rails.ajax({
          url:'/admin/categories/sort',
          type: 'PUT',
          data,
          success: res => {
            console.log(res);
          }, 
          error: err => {
            console.log(err);
          }
        })
      }
    });
  }
})