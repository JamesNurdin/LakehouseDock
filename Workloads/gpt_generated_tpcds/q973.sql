WITH store_month_sales AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2020-01-01' AND d.d_date < DATE '2021-01-01'
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq, i.i_category
)
SELECT
    sm.s_store_name,
    sm.d_year,
    sm.d_month_seq,
    sm.i_category,
    sm.total_sales,
    sm.total_quantity,
    sm.avg_sales_price,
    sm.total_discount,
    sm.total_discount / CASE WHEN sm.total_sales = 0 THEN NULL ELSE sm.total_sales END AS discount_rate,
    ROW_NUMBER() OVER (PARTITION BY sm.d_year, sm.d_month_seq ORDER BY sm.total_sales DESC) AS sales_rank
FROM store_month_sales sm
ORDER BY sm.d_year, sm.d_month_seq, sales_rank
LIMIT 100
