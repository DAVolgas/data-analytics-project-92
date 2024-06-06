-- запрос выводит общее количество покупателей
select COUNT(customer_id) as customers_count from customers

-- отчет о десятке лучших продавцов
select 
	e.first_name ||' '|| e.last_name as seller,
	COUNT(s.sales_id) as operations,
	floor(SUM(s.quantity * p.price)) as income
from employees e 
inner join sales s 
	on s.sales_person_id = e.employee_id 
inner join products p 
	on p.product_id = s.product_id 
group by e.first_name ||' '|| e.last_name
order by floor(SUM(s.quantity * p.price)) desc
limit 10

-- создаем СТЕ с расчетом средней выручки по всем продавцам с округлением в меньшую сторону до целого числа
with total_avg_amount as
(
	select 
		floor(AVG(s.quantity * p.price)) as total_average_income
	from sales s 
	inner join products p 
		on s.product_id = p.product_id 
)
-- отчет о продавцах, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам
select 											
	e.first_name ||' '|| e.last_name as seller,
	floor(AVG(s.quantity * p.price)) as average_income
from employees e
inner join sales s 
	on s.sales_person_id = e.employee_id 
inner join products p
	on p.product_id = s.product_id
group by e.first_name ||' '|| e.last_name
having floor(AVG(s.quantity * p.price)) < (select total_average_income from total_avg_amount)
order by floor(AVG(s.quantity * p.price)) asc

-- в СТЕ выводим номер и название дня недели + имена и фамалии продавцов + суммарная выручка
with dow_amount as
(
select 
	e.first_name ||' '|| e.last_name as seller,
	extract (isodow from s.sale_date) as day_number,
	to_char(s.sale_date, 'day') as day_of_week,
	floor(SUM(s.quantity * p.price)) as income
from employees e
inner join sales s 								
	on s.sales_person_id = e.employee_id 
inner join products p
	on p.product_id = s.product_id
group by e.first_name ||' '|| e.last_name, to_char(s.sale_date, 'day'), extract (isodow from s.sale_date)
order by extract (isodow from s.sale_date), e.first_name ||' '|| e.last_name
)
-- запрос для вывода необходимой для отчета информации
select				 
	seller,
	day_of_week,
	income
from dow_amount

-- добавляем поле с возрастными категориями
with age_cat as
(
select *,
	case 
		when c.age between 16 and 25 then '16-25'
		when c.age between 26 and 40 then '26-40'
		when c.age > 40 then '40+'
	end as age_category
from customers c
)
-- считаем количество покупателй по возрастным категориям
select
	age_category,
	count(age) as age_count
from age_cat
group by age_category
order by age_category

-- выводим количество покупателй и выручку по месяцам
select
	to_char(s.sale_date, 'yyyy-mm') as selling_month,
	count(distinct s.customer_id) as total_customers,
	floor(sum(s.quantity * p.price)) as income
from sales s
inner join products p
	on s.product_id = p.product_id 
group by to_char(s.sale_date, 'yyyy-mm')
order by to_char(s.sale_date, 'yyyy-mm')

-- CTE - добавляем нумерацию строк акционных продаж по id покупателя с сортировкой по дате и id покупателя
with rn_tab as
(
select *,
	row_number () over (partition by s.customer_id order by s.sale_date, s.customer_id) as rn
from sales s 
inner join products p 
	on s.product_id = p.product_id 
where p.price = 0
)
-- выводим информацию для отчета
select 				 
	c.first_name ||' '|| c.last_name as customer,
	r.sale_date,
	e.first_name ||' '|| e.last_name as seller
from rn_tab r
inner join employees e 
	on e.employee_id = r.sales_person_id
inner join customers c 
	on c.customer_id = r.customer_id
where r.rn = 1
