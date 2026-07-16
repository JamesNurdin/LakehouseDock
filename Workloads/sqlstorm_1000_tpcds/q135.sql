with years_quarters as (
    select d_year as sales_year, d_quarter_seq as quarter
    from date_dim
    where d_year between 1999 and 2001
    group by d_year, d_quarter_seq
),
store_sales_agg as (
    select
        d.d_year as sales_year,
        d.d_quarter_seq as quarter,
        sum(ss.ss_net_profit) as store_net_profit,
        sum(ss.ss_ext_sales_price) as store_gross_sales,
        sum(ss.ss_ext_discount_amt) as store_discount,
        count(*) as store_transactions
    from store_sales ss
    join date_dim d on ss.ss_sold_date_sk = d.d_date_sk
    where d.d_year between 1999 and 2001
    group by d.d_year, d.d_quarter_seq
),
store_returns_agg as (
    select
        d.d_year as sales_year,
        d.d_quarter_seq as quarter,
        sum(sr.sr_net_loss) as store_net_loss,
        sum(sr.sr_return_amt) as store_return_amount,
        count(*) as store_return_transactions
    from store_returns sr
    join date_dim d on sr.sr_returned_date_sk = d.d_date_sk
    where d.d_year between 1999 and 2001
    group by d.d_year, d.d_quarter_seq
),
catalog_sales_agg as (
    select
        d.d_year as sales_year,
        d.d_quarter_seq as quarter,
        sum(cs.cs_net_profit) as catalog_net_profit,
        sum(cs.cs_ext_sales_price) as catalog_gross_sales,
        sum(cs.cs_ext_discount_amt) as catalog_discount,
        count(*) as catalog_transactions
    from catalog_sales cs
    join date_dim d on cs.cs_sold_date_sk = d.d_date_sk
    where d.d_year between 1999 and 2001
    group by d.d_year, d.d_quarter_seq
),
catalog_returns_agg as (
    select
        d.d_year as sales_year,
        d.d_quarter_seq as quarter,
        sum(cr.cr_net_loss) as catalog_net_loss,
        sum(cr.cr_return_amount) as catalog_return_amount,
        count(*) as catalog_return_transactions
    from catalog_returns cr
    join date_dim d on cr.cr_returned_date_sk = d.d_date_sk
    where d.d_year between 1999 and 2001
    group by d.d_year, d.d_quarter_seq
),
web_sales_agg as (
    select
        d.d_year as sales_year,
        d.d_quarter_seq as quarter,
        sum(ws.ws_net_profit) as web_net_profit,
        sum(ws.ws_ext_sales_price) as web_gross_sales,
        sum(ws.ws_ext_discount_amt) as web_discount,
        count(*) as web_transactions
    from web_sales ws
    join date_dim d on ws.ws_sold_date_sk = d.d_date_sk
    where d.d_year between 1999 and 2001
    group by d.d_year, d.d_quarter_seq
),
web_returns_agg as (
    select
        d.d_year as sales_year,
        d.d_quarter_seq as quarter,
        sum(wr.wr_net_loss) as web_net_loss,
        sum(wr.wr_return_amt) as web_return_amount,
        count(*) as web_return_transactions
    from web_returns wr
    join date_dim d on wr.wr_returned_date_sk = d.d_date_sk
    where d.d_year between 1999 and 2001
    group by d.d_year, d.d_quarter_seq
)
select
    sales_year,
    quarter,
    total_gross_sales,
    total_discount,
    total_net_profit,
    round(100.0 * total_discount / nullif(total_gross_sales, 0), 2) as discount_percentage,
    round(100.0 * total_net_profit / nullif(total_gross_sales, 0), 2) as profit_margin,
    rank() over (order by total_net_profit desc) as profit_rank,
    lag(total_net_profit) over (order by sales_year, quarter) as prev_quarter_net_profit,
    total_net_profit - lag(total_net_profit) over (order by sales_year, quarter) as net_profit_qoq_change,
    round(
        100.0 * (total_net_profit - lag(total_net_profit) over (order by sales_year, quarter))
        / nullif(lag(total_net_profit) over (order by sales_year, quarter), 0),
        2
    ) as net_profit_qoq_pct_change
from (
    select
        y.sales_year,
        y.quarter,
        coalesce(ss.store_gross_sales, 0) + coalesce(cs.catalog_gross_sales, 0) + coalesce(ws.web_gross_sales, 0) as total_gross_sales,
        coalesce(ss.store_discount, 0) + coalesce(cs.catalog_discount, 0) + coalesce(ws.web_discount, 0) as total_discount,
        coalesce(ss.store_net_profit, 0) + coalesce(cs.catalog_net_profit, 0) + coalesce(ws.web_net_profit, 0)
        - coalesce(sr.store_net_loss, 0) - coalesce(cr.catalog_net_loss, 0) - coalesce(wr.web_net_loss, 0) as total_net_profit
    from years_quarters y
    left join store_sales_agg ss on y.sales_year = ss.sales_year and y.quarter = ss.quarter
    left join store_returns_agg sr on y.sales_year = sr.sales_year and y.quarter = sr.quarter
    left join catalog_sales_agg cs on y.sales_year = cs.sales_year and y.quarter = cs.quarter
    left join catalog_returns_agg cr on y.sales_year = cr.sales_year and y.quarter = cr.quarter
    left join web_sales_agg ws on y.sales_year = ws.sales_year and y.quarter = ws.quarter
    left join web_returns_agg wr on y.sales_year = wr.sales_year and y.quarter = wr.quarter
) t
order by sales_year, quarter
