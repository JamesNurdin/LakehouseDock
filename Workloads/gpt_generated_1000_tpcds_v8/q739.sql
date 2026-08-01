WITH sales_base AS (
    SELECT
        s.s_store_id AS store_id,
        td.t_hour AS hour_of_day,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY GROUPING SETS (
        (s.s_store_id, td.t_hour),
        (s.s_store_id)
    )
    HAVING SUM(ss.ss_ext_sales_price) > 1000
),
sales_agg AS (
    SELECT
        store_id,
        hour_of_day,
        total_sales,
        total_profit,
        CASE WHEN total_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_sales DESC) AS sales_rank
    FROM sales_base
),
returns_agg AS (
    SELECT
        s.s_store_id AS store_id,
        SUM(sr.sr_return_amt) AS total_returns
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_id
),
final_union AS (
    SELECT
        store_id,
        hour_of_day,
        total_sales,
        total_profit,
        profit_flag,
        sales_rank
    FROM sales_agg
    WHERE store_id NOT IN (SELECT s_store_id FROM store WHERE s_state = 'CA')
    UNION
    SELECT
        store_id,
        NULL AS hour_of_day,
        total_returns AS total_sales,
        NULL AS total_profit,
        NULL AS profit_flag,
        NULL AS sales_rank
    FROM returns_agg
    WHERE total_returns > 0
),
final_exclude AS (
    SELECT
        store_id,
        NULL AS hour_of_day,
        total_returns AS total_sales,
        NULL AS total_profit,
        NULL AS profit_flag,
        NULL AS sales_rank
    FROM returns_agg
    WHERE total_returns > 5000
)
SELECT *
FROM final_union
EXCEPT
SELECT *
FROM final_exclude
ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
