with all_sales as (
    select ss_sold_date_sk as sale_date_sk,
           ss_item_sk as item_sk,
           ss_quantity as quantity,
           ss_net_paid as net_paid,
           ss_net_profit as net_profit,
           'store' as channel
    from store_sales
    union all
    select cs_sold_date_sk as sale_date_sk,
           cs_item_sk as item_sk,
           cs_quantity as quantity,
           cs_net_paid as net_paid,
           cs_net_profit as net_profit,
           'catalog' as channel
    from catalog_sales
    union all
    select ws_sold_date_sk as sale_date_sk,
           ws_item_sk as item_sk,
           ws_quantity as quantity,
           ws_net_paid as net_paid,
           ws_net_profit as net_profit,
           'web' as channel
    from web_sales
),
sales_agg as (
    select s.item_sk,
           sum(s.quantity) as total_quantity,
           sum(s.net_paid) as total_net_paid,
           sum(s.net_profit) as total_net_profit,
           count(distinct s.sale_date_sk) as distinct_sale_days,
           max(s.sale_date_sk) as last_sale_date_sk
    from all_sales s
    group by s.item_sk
),
returns as (
    select sr_item_sk as item_sk,
           sum(sr_return_quantity) as return_quantity,
           sum(sr_net_loss) as return_net_loss
    from store_returns
    group by sr_item_sk
    union all
    select cr_item_sk as item_sk,
           sum(cr_return_quantity) as return_quantity,
           sum(cr_net_loss) as return_net_loss
    from catalog_returns
    group by cr_item_sk
    union all
    select wr_item_sk as item_sk,
           sum(wr_return_quantity) as return_quantity,
           sum(wr_net_loss) as return_net_loss
    from web_returns
    group by wr_item_sk
),
returns_agg as (
    select r.item_sk,
           sum(r.return_quantity) as total_return_quantity,
           sum(r.return_net_loss) as total_return_net_loss
    from returns r
    group by r.item_sk
),
promo_stats as (
    select p.p_item_sk as item_sk,
           avg(p.p_cost) as avg_promo_cost,
           count(*) as promo_count
    from promotion p
    group by p.p_item_sk
),
item_detail as (
    select i.i_item_sk,
           i.i_product_name,
           i.i_brand,
           i.i_category,
           i.i_class,
           i.i_current_price,
           i.i_rec_start_date,
           i.i_rec_end_date
    from item i
),
last_sales as (
    select s.item_sk,
           max(s.sale_date_sk) as last_sale_date_sk
    from all_sales s
    group by s.item_sk
)
select
    i.i_item_sk as item_sk,
    concat(i.i_product_name, ' (', i.i_brand, ')') as full_name,
    i.i_category,
    i.i_class,
    i.i_current_price,
    coalesce(s.total_quantity, 0) as total_quantity_sold,
    coalesce(s.total_net_paid, 0.0) as total_net_paid,
    coalesce(s.total_net_profit, 0.0) as total_net_profit,
    coalesce(r.total_return_quantity, 0) as total_return_quantity,
    coalesce(r.total_return_net_loss, 0.0) as total_return_net_loss,
    coalesce(s.total_net_paid, 0.0) - coalesce(r.total_return_net_loss, 0.0) as net_revenue_after_returns,
    case
        when (coalesce(s.total_net_paid, 0.0) - coalesce(r.total_return_net_loss, 0.0)) = 0 then 0
        else round(((coalesce(s.total_net_profit, 0.0) - coalesce(r.total_return_net_loss, 0.0))
                    / (coalesce(s.total_net_paid, 0.0) - coalesce(r.total_return_net_loss, 0.0))) * 100, 2)
    end as profit_margin_percent,
    p.promo_count,
    round(p.avg_promo_cost, 2) as avg_promo_cost,
    (select avg(ws_ext_ship_cost) from web_sales ws where ws.ws_item_sk = i.i_item_sk) as avg_web_ship_cost,
    (select sum(ss_quantity) from store_sales ss where ss.ss_item_sk = i.i_item_sk) as total_store_quantity,
    date_diff('day', DATE '2024-10-01', dd.d_date) as days_since_last_sale,
    rank() over (partition by i.i_category order by (coalesce(s.total_net_paid, 0.0) - coalesce(r.total_return_net_loss, 0.0)) desc) as category_sales_rank,
    case
        when i.i_rec_end_date is not null and i.i_rec_end_date < DATE '2024-10-01' then 'DISCONTINUED'
        when i.i_rec_start_date > DATE '2024-10-01' then 'NOT YET RELEASED'
        else 'ACTIVE'
    end as item_status
from item_detail i
left join sales_agg s on i.i_item_sk = s.item_sk
left join returns_agg r on i.i_item_sk = r.item_sk
left join promo_stats p on i.i_item_sk = p.item_sk
left join last_sales ls on i.i_item_sk = ls.item_sk
left join date_dim dd on ls.last_sale_date_sk = dd.d_date_sk
where (i.i_current_price is not null or s.item_sk is not null)
order by net_revenue_after_returns desc
limit 100
