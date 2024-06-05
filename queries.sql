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
	to_char(s.sale_date, 'Day') as day_of_week,			-- из даты продижи берем название дня недели и убираем лишние пробелы
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

with age_cat as			-- добавляем поле с возрастными категориями
(
select *,
	case 
		when c.age between 16 and 25 then '16-25'
		when c.age between 26 and 40 then '26-40'
		when c.age > 40 then '40+'
	end as age_category
from customers c
)
select					-- считаем количество покупателй по возрастным категориям
	age_category,
	count(age) as age_count
from age_cat
group by age_category
order by age_category


select 					-- выводим количество покупателй и выручку по месяцам
	to_char(s.sale_date, 'yyyy-mm') as selling_month,  	-- переводим дату в требуемый вид
	count(distinct s.customer_id) as total_customers,	-- считаем уникальных покупателей
	floor(sum(s.quantity * p.price)) as income 			-- выручка с округлением до целого в меньшую сторону 
from sales s
inner join products p 									-- присоединем таблицу с продуктами для расчета выучки
	on s.product_id = p.product_id 
group by to_char(s.sale_date, 'yyyy-mm')				-- группировка по месяцам
order by to_char(s.sale_date, 'yyyy-mm')				-- сортировака по месяцам по возрастанию


with rn_tab as		-- CTE - добавляем нумерацию строк акционных продаж по id покупателя с сортировкой по дате и id покупателя
(
select *,
	row_number () over (partition by s.customer_id order by s.sale_date, s.customer_id) as rn
from sales s 
inner join products p 
	on s.product_id = p.product_id 
where p.price = 0		-- отбираем продажи с ценой 0 (акционные товары)
)

select 				-- выводим информацию для отчета 
	c.first_name ||' '|| c.last_name as customer,	-- объединение имени и фамилии покупателей в одно поле
	r.sale_date,
	e.first_name ||' '|| e.last_name as seller		-- бъединение имени и фамилии продавцов в одно поле
from rn_tab r
inner join employees e 
	on e.employee_id = r.sales_person_id
inner join customers c 
	on c.customer_id = r.customer_id
where r.rn = 1										-- отбираем строки с первой датой продажи по акции