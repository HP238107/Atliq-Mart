use retail_events_db;

select p.product_code,p.product_name,p.category,f.promo_type,f.base_price
from dim_products as p 
join fact_events as f 
on p.product_code=f.product_code 
where f.base_price > 500 
and f.promo_type="BOGOF"
group by p.product_name;

select city, count(city) as city_count from dim_stores
group by city
order by city_count desc ;


with cte as
(select campaign_id,`quantity_sold(before_promo)`,base_price, `quantity_sold(after_promo)`,promo_type,
case when promo_type= "50% OFF" then round((base_price/2) * `quantity_sold(after_promo)`,0)
when promo_type= "25% OFF" then round((base_price*0.25) * `quantity_sold(after_promo)`,0)
when promo_type= "33% OFF" then round((base_price*0.33) * `quantity_sold(after_promo)`,0)
when promo_type= "BOGOF" then round((base_price/2) * `quantity_sold(after_promo)`,0)
when promo_type= "500 Cashback" then 500
end  as discount,base_price* `quantity_sold(after_promo)` as revenue,
`quantity_sold(before_promo)`*base_price as revenue_befo_promo
from fact_events)
select d.campaign_name,
case when c.revenue_befo_promo > 1000 and c.revenue_befo_promo < 1000000 
then concat(round(c.revenue_befo_promo/ 1000,2),"k")
when c.revenue_befo_promo >= 1000000 then concat(round(c.revenue_befo_promo/1000000,2),"M")
else c.revenue_befo_promo
end as Revenue_befo_promo,
case when (c.revenue-c.discount) > 1000 and (c.revenue-c.discount) < 1000000 
then concat(round((c.revenue-c.discount)/ 1000,2),"k")
when (c.revenue-c.discount) >= 1000000 then concat(round((c.revenue-c.discount)/1000000,2),"M")
else (c.revenue-c.discount)
end as Revenue_after_promo
from cte as c join dim_campaigns as d  on c.campaign_id=d.campaign_id;



 
 
 with ir as
(select p.product_code,p.category,p.product_name,f.base_price* f.`quantity_sold(before_promo)`
as rev_before, 
case when f.promo_type= "50% OFF" then  round((f.base_price* f.`quantity_sold(after_promo)`)*0.50,0)
when f.promo_type= "25% OFF" then round(( f.base_price* f.`quantity_sold(after_promo)`)*0.75,0)
when f.promo_type= "33% OFF" then round(( f.base_price* f.`quantity_sold(after_promo)`)*0.67,0)
when f.promo_type= "BOGOF" then round(( f.base_price* f.`quantity_sold(after_promo)`)*0.50,0)
when f.promo_type= "500 Cashback" then round(( f.base_price* f.`quantity_sold(after_promo)`)-500,0)
end as Rev_after 
from dim_products as p join fact_events as f on 
p.product_code=f.product_code)
select category,product_name,round(sum((((Rev_after-rev_before)/rev_before)*100)),2) as IR from ir
group by product_name 
order by IR 
desc limit 5;