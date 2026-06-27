WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        ds.d_year,
        ds.d_month_seq,
        ds.d_moy,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        AVG(t.t_hour) AS avg_sale_hour
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ds.d_year = 2022
    GROUP BY s.s_store_sk, s.s_store_name, ds.d_year, ds.d_month_seq, ds.d_moy
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        ds.d_year,
        ds.d_month_seq,
        ds.d_moy,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT sr.sr_item_sk) AS distinct_items_returned,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers_returned,
        AVG(t.t_hour) AS avg_return_hour
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim ds ON sr.sr_returned_date_sk = ds.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE ds.d_year = 2022
    GROUP BY s.s_store_sk, ds.d_year, ds.d_month_seq, ds.d_moy
)
SELECT
    sa.s_store_name,
    sa.d_year,
    sa.d_moy,
    sa.total_sales,
    sa.total_profit,
    ra.total_return_amount,
    ra.total_return_loss,
    (sa.total_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
    sa.total_discount,
    sa.distinct_items_sold,
    ra.distinct_items_returned,
    sa.distinct_customers,
    ra.distinct_customers_returned,
    sa.avg_sale_hour,
    ra.avg_return_hour
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
   AND sa.d_year = ra.d_year
   AND sa.d_month_seq = ra.d_month_seq
ORDER BY net_profit_after_returns DESC
LIMIT 20
