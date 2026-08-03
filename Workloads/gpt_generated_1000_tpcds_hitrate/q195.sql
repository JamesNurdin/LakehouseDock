with sales_data as (
  select
    ss.ss_sold_date_sk as date_sk,
    ss.ss_item_sk as item_sk,
    i.i_category as category,
    td.t_hour as hour,
    ss.ss_net_paid as amount,
    c.c_customer_id as customer_id
  from store_sales ss
  join item i on ss.ss_item_sk = i.i_item_sk
  join time_dim td on ss.ss_sold_time_sk = td.t_time_sk
  join customer c on ss.ss_customer_sk = c.c_customer_sk
  where i.i_class_id = 6
    and exists (
      select 1
      from household_demographics hd
      join income_band ib on hd.hd_income_band_sk = ib.ib_income_band_sk
      where hd.hd_demo_sk = c.c_current_hdemo_sk
        and ib.ib_upper_bound >= 100000
    )
),

returns_data as (
  select
    cr.cr_returned_date_sk as date_sk,
    cr.cr_item_sk as item_sk,
    i.i_category as category,
    td.t_hour as hour,
    cr.cr_return_amount as amount,
    c.c_customer_id as customer_id
  from catalog_returns cr
  join item i on cr.cr_item_sk = i.i_item_sk
  join time_dim td on cr.cr_returned_time_sk = td.t_time_sk
  join customer c on cr.cr_refunded_customer_sk = c.c_customer_sk
  where i.i_class_id = 6
    and c.c_preferred_cust_flag = 'Y'
),

full_combined as (
  select
    coalesce(s.date_sk, r.date_sk) as date_sk,
    coalesce(s.item_sk, r.item_sk) as item_sk,
    coalesce(s.category, r.category) as category,
    coalesce(s.hour, r.hour) as hour,
    s.amount as sales_amount,
    r.amount as return_amount,
    coalesce(s.customer_id, r.customer_id) as customer_id,
    case
      when s.item_sk is not null and r.item_sk is not null then 'Both'
      when s.item_sk is not null then 'SaleOnly'
      else 'ReturnOnly'
    end as source
  from sales_data s
  full outer join returns_data r
    on s.item_sk = r.item_sk
   and s.date_sk = r.date_sk
   and s.customer_id = r.customer_id
)

-- detailed rows
select
  date_sk,
  item_sk,
  category,
  hour,
  sum(sales_amount) as total_sales,
  sum(return_amount) as total_returns,
  count(*) as row_cnt,
  source
from full_combined
group by date_sk, item_sk, category, hour, source
having sum(sales_amount) > 0 or sum(return_amount) > 0

union all

-- aggregated across sources
select
  date_sk,
  item_sk,
  category,
  hour,
  sum(total_sales) as total_sales,
  sum(total_returns) as total_returns,
  sum(row_cnt) as row_cnt,
  'Aggregated' as source
from (
  select
    date_sk,
    item_sk,
    category,
    hour,
    total_sales,
    total_returns,
    row_cnt,
    source
  from (
    select
      date_sk,
      item_sk,
      category,
      hour,
      sum(sales_amount) as total_sales,
      sum(return_amount) as total_returns,
      count(*) as row_cnt,
      source
    from full_combined
    group by date_sk, item_sk, category, hour, source
  )
) agg
group by date_sk, item_sk, category, hour
limit 100
