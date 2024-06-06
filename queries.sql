-- запрос выводит общее количество покупателей
select COUNT(customer_id) as customers_count from customers;

-- отчет о десятке лучших продавцов 
select
    e.first_name || ' ' || e.last_name as seller,
    COUNT(s.sales_id) as operations,
    FLOOR(SUM(s.quantity * p.price)) as income
from employees as e
inner join sales as s
    on e.employee_id = s.sales_person_id
inner join products as p
    on s.product_id = p.product_id
group by e.first_name || ' ' || e.last_name
order by FLOOR(SUM(s.quantity * p.price)) desc
limit 10;

-- СТЕ средняя выручка по всем продавцам с округлением
with total_avg_amount as (
    select FLOOR(AVG(s.quantity * p.price)) as total_average_income
    from sales as s
    inner join products as p
        on s.product_id = p.product_id
)

-- отчет о продавцах, чья средняя выручка за сделку
-- меньше средней выручки за сделку по всем продавцам
select
    e.first_name || ' ' || e.last_name as seller,
    FLOOR(AVG(s.quantity * p.price)) as average_income
from employees as e
inner join sales as s
    on e.employee_id = s.sales_person_id
inner join products as p
    on s.product_id = p.product_id
group by e.first_name || ' ' || e.last_name
having
    FLOOR(AVG(s.quantity * p.price))
    < (select total_average_income from total_avg_amount)
order by FLOOR(AVG(s.quantity * p.price)) asc;


-- в СТЕ номер и название дня недели
with dow_amount as (
    select
        e.first_name || ' ' || e.last_name as seller,
        EXTRACT(isodow from s.sale_date) as day_number,
        TO_CHAR(s.sale_date, 'day') as day_of_week,
        FLOOR(SUM(s.quantity * p.price)) as income
    from employees as e
    inner join sales as s
        on e.employee_id = s.sales_person_id
    inner join products as p
        on s.product_id = p.product_id
    group by
        e.first_name || ' ' || e.last_name,
        TO_CHAR(s.sale_date, 'day'),
        EXTRACT(isodow from s.sale_date)
    order by
        EXTRACT(isodow from s.sale_date), e.first_name || ' ' || e.last_name
)

-- запрос для вывода необходимой для отчета информации
select
    seller,
    day_of_week,
    income
from dow_amount;


-- добавляем поле с возрастными категориями
with age_cat as (
    select
        *,
        case
            when age between 16 and 25 then '16-25'
            when age between 26 and 40 then '26-40'
            when age > 40 then '40+'
        end as age_category
    from customers
)

-- считаем количество покупателй по возрастным категориям
select
    age_category,
    COUNT(age) as age_count
from age_cat
group by age_category
order by age_category;

-- выводим количество покупателй и выручку по месяцам
select
    TO_CHAR(s.sale_date, 'yyyy-mm') as selling_month,
    COUNT(distinct s.customer_id) as total_customers,
    FLOOR(SUM(s.quantity * p.price)) as income
from sales as s
inner join products as p
    on s.product_id = p.product_id
group by TO_CHAR(s.sale_date, 'yyyy-mm')
order by TO_CHAR(s.sale_date, 'yyyy-mm');

-- CTE нумерацию строк акционных продаж
with rn_tab as (
    select
        s.*,
        ROW_NUMBER()
            over (
                partition by s.customer_id order by s.sale_date, s.customer_id
            )
        as rn
    from sales as s
    inner join products as p
        on s.product_id = p.product_id
    where p.price = 0
)

-- выводим информацию для отчета
select
    r.sale_date,
    c.first_name || ' ' || c.last_name as customer,
    e.first_name || ' ' || e.last_name as seller
from rn_tab as r
inner join employees as e
    on r.sales_person_id = e.employee_id
inner join customers as c
    on r.customer_id = c.customer_id
where r.rn = 1;
