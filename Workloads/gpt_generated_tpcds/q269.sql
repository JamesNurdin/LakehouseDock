WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_sales.d_year,
        d_sales.d_month_seq,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d_sales.d_year = 2001
    GROUP BY
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_sales.d_year,
        d_sales.d_month_seq,
        i.i_category
),

returns_agg AS (
    SELECT
        s.s_store_sk,
        d_return.d_year,
        d_return.d_month_seq,
        i.i_category,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d_return.d_year = 2001
    GROUP BY
        s.s_store_sk,
        d_return.d_year,
        d_return.d_month_seq,
        i.i_category
)

SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.s_city,
    sa.s_state,
    sa.d_year,
    sa.d_month_seq,
    sa.i_category,
    sa.total_sales,
    COALESCE(ra.total_returns, 0) AS total_returns,
    sa.total_profit,
    sa.distinct_customers,
    sa.total_quantity,
    sa.avg_sales_price,
    (sa.total_sales - COALESCE(ra.total_returns, 0)) AS net_sales_after_returns,
    CASE
        WHEN sa.total_quantity > 0 THEN COALESCE(ra.total_return_qty, 0) / sa.total_quantity
        ELSE 0
    END AS return_rate
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
   AND sa.d_year = ra.d_year
   AND sa.d_month_seq = ra.d_month_seq
   AND sa.i_category = ra.i_category
ORDER BY
    sa.s_store_id,
    sa.d_year,
    sa.d_month_seq,
    sa.i_category
