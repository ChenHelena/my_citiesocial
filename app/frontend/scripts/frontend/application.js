import bulmaCarousel from 'bulma-carousel';

document.addEventListener('turbolinks:load', () => {
  bulmaCarousel.attach('#carousel-demo', {
    slidesToScroll: 1,
    slidesToShow: 3, 
    infinite: true
  });
})
