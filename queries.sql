select COUNT(customer_id) as customers_count from customers c 
-- запрос выводит общее количество записей в поле customer_id таблицы customers и присваивает полю в результате запроса имя customers_count
-- т.к. customer_id уникальный для каждого покупателя, то в результате запроса выводится общее количество покупателей

select 											-- отчет о десятке лучших продавцов
	e.first_name ||' '|| e.last_name as seller, -- объединение имени и фамилии в одно поле
	COUNT(s.sales_id) as operations,			-- подсчет количества сделок
	floor(SUM(s.quantity * p.price)) as income  -- суммарная выручка с округлением в меньшую сторону до целого числа
from employees e 
inner join sales s 								-- присоединяем таблицу sales
	on s.sales_person_id = e.employee_id 
inner join products p							-- присоединяем таблицу roducts
	on p.product_id = s.product_id 
group by e.first_name ||' '|| e.last_name		-- выполняем группировку по имени и фамилии продавца, т.к. необходимо получить данные по продавцам
order by floor(SUM(s.quantity * p.price)) desc  -- сортировка по выручке в убывающем порядке для дальнейшего отбора топ-10 продавцов
limit 10										-- отфильтровываем топ-10 по выручке (первые 10 строк из результата запроса)


with total_avg_amount as						-- создаем СТЕ с расчетом средней выручки по всем продавцам с округлением в меньшую сторону до целого числа
(
	select 
		floor(AVG(s.quantity * p.price)) as total_average_income
	from sales s 
	inner join products p 
		on s.product_id = p.product_id 
)
select 											-- отчет о продавцах, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам
	e.first_name ||' '|| e.last_name as seller, -- объединяяем имя и фамилию в одно поле
	floor(AVG(s.quantity * p.price)) as average_income -- средняя выручка с округлением в меньшую сторону до целого числа 
from employees e
inner join sales s 								-- присоединяем таблицу sales
	on s.sales_person_id = e.employee_id 
inner join products p							-- присоединяем таблицу products
	on p.product_id = s.product_id
group by e.first_name ||' '|| e.last_name		-- выполняем группировку по имени и фамилии продавца, т.к. необходимо получить данные по продавцам
having floor(AVG(s.quantity * p.price)) < (select total_average_income from total_avg_amount) -- применяем условие фильтрации
order by floor(AVG(s.quantity * p.price)) asc 	-- сортировка согласно условиям задачи


with dow_amount as								-- в СТЕ выводим номер и название дня недели + имена и фамалии продавцов + суммарная выручка 
(
select 
	e.first_name ||' '|| e.last_name as seller, 		-- объединение имени и фамилии в одно поле
	extract (isodow from s.sale_date) as day_number,	-- из даты продажи берем номер дня недели (пн = 1 ... вс = 7 ISO 8601)
	to_char(s.sale_date, 'Day') as day_of_week,			-- из даты продижи берем название дня недели
	floor(SUM(s.quantity * p.price)) as income			-- суммарная выручка с округлением в меньшую сторону до целого числа
from employees e 										--	присоединяем таблицу sales
inner join sales s 								
	on s.sales_person_id = e.employee_id 
inner join products p									-- присоединяем таблицу products
	on p.product_id = s.product_id
group by e.first_name ||' '|| e.last_name, to_char(s.sale_date, 'Day'), extract (isodow from s.sale_date) -- группировка по необходимым полям
order by extract (isodow from s.sale_date), e.first_name ||' '|| e.last_name		-- сортировка по номеру дня недели 
)
select				-- запрос для вывода необходимой для отчета информации 
	seller,
	day_of_week,
	income
from dow_amount

