WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_tax) AS avg_tax
    FROM
        store_sales ss
        INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year >= 1998 AND
        d.d_year <= 2000 AND
        d.d_weekend = 'N' AND
        d.d_dow IN (1, 2, 3) AND
        d.d_fy_quarter_seq = 20 AND
        ss.ss_ext_sales_price > 1000 AND
        ss.ss_quantity >= 1 AND
        ss.ss_coupon_amt = 0.00
    GROUP BY
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq
)
SELECT
    ss_store_sk,
    d_year,
    d_month_seq,
    total_sales,
    total_profit,
    avg_tax,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank_year,
    CASE WHEN total_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_category
FROM
    sales_agg
ORDER BY
    d_year,
    sales_rank_year,
    total_sales DESC
LIMIT 100
