with
  returns_agg as (
    select
      sr.sr_item_sk as item_sk,
      sum(sr.sr_return_amt) as total_return_amt,
      sum(sr.sr_net_loss) as total_net_loss
    from store_returns sr
    group by sr.sr_item_sk
  ),
  sales_agg as (
    select
      ws.ws_item_sk as item_sk,
      sum(ws.ws_ext_sales_price) as total_sales,
      sum(ws.ws_net_profit) as total_net_profit
    from web_sales ws
    group by ws.ws_item_sk
  )
select
  t.i_category,
  t.i_item_id,
  t.i_product_name,
  t.short_name,
  t.numeric_part,
  t.brand_product,
  t.total_return_amt,
  t.total_sales,
  t.total_net_profit
from (
  select
    i.i_category,
    i.i_item_id,
    i.i_product_name,
    substring(i.i_product_name, 1, 10) as short_name,
    regexp_extract(i.i_item_id, '(\\d+)', 1) as numeric_part,
    concat(i.i_brand, ' - ', i.i_product_name) as brand_product,
    r.total_return_amt,
    s.total_sales,
    s.total_net_profit,
    row_number() over (partition by i.i_category order by s.total_sales desc) as rn
  from item i
  join returns_agg r on r.item_sk = i.i_item_sk
  join sales_agg s on s.item_sk = i.i_item_sk
  where regexp_like(i.i_item_desc, '\\d+[a-zA-Z]+')
    and i.i_category like 'Electronics%'
    and i.i_units = 'Each'
    and i.i_formulation like '%steel%'
) t
where t.rn <= 5
limit 100
