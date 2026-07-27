WITH agg_sales AS (
    SELECT
        i.i_category AS category,
        d.d_year AS year,
        s.s_state AS state,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE
            WHEN SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_quantity), 0) > 50 THEN 'HIGH'
            ELSE 'LOW'
        END AS profit_level
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year IN (2001, 2002)
    GROUP BY i.i_category, d.d_year, s.s_state
    HAVING SUM(ss.ss_ext_sales_price) > 5000
)
SELECT category,
       state,
       total_sales,
       profit_level
FROM agg_sales
WHERE year = 2001
UNION ALL
SELECT category,
       state,
       total_sales,
       profit_level
FROM agg_sales
WHERE year = 2002
ORDER BY total_sales DESC
LIMIT 100
