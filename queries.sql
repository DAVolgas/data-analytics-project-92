select COUNT(customer_id) as customers_count from customers c 
-- запрос выводит общее количество записей в поле customer_id таблицы customers и присваивает полю в результате запроса имя customers_count
-- т.к. customer_id уникальный для каждого покупателя, то в результате запроса выводится общее количество покупателей