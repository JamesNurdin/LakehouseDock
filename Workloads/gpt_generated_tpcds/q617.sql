WITH sales_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2020-01-01' AND d.d_date < DATE '2021-01-01'
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(r.sr_return_amt) AS total_return_amount
    FROM store_returns r
    JOIN store s ON r.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON r.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON r.sr_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2020-01-01' AND d.d_date < DATE '2021-01-01'
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq, i.i_category
)
SELECT
    sa.s_store_name,
    sa.d_year,
    sa.d_month_seq,
    sa.i_category,
    sa.total_sales,
    sa.total_discount,
    sa.total_profit,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    (COALESCE(ra.total_return_amount, 0) / NULLIF(sa.total_sales, 0)) * 100 AS return_rate_percent,
    SUM(sa.total_sales) OVER (PARTITION BY sa.s_store_name, sa.d_year, sa.d_month_seq) AS store_month_total_sales,
    (sa.total_sales / SUM(sa.total_sales) OVER (PARTITION BY sa.s_store_name, sa.d_year, sa.d_month_seq)) * 100 AS category_sales_pct
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_name = ra.s_store_name
    AND sa.d_year = ra.d_year
    AND sa.d_month_seq = ra.d_month_seq
    AND sa.i_category = ra.i_category
ORDER BY sa.total_sales DESC
LIMIT 100
