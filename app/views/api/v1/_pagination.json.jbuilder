# Metadatos de paginación comunes a todas las colecciones de la API.
# El local no puede llamarse `collection`: jbuilder reserva esa clave para
# renderizar el parcial una vez por elemento.
json.current_page paginator.current_page
json.next_page    paginator.next_page
json.prev_page    paginator.prev_page
json.total_pages  paginator.total_pages
json.total_count  paginator.total_count
json.per_page     paginator.limit_value
