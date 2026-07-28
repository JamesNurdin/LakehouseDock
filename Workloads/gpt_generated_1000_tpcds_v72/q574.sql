WITH sales_agg AS (
    SELECT
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_profit) AS avg_profit,
        MIN(ss_ext_sales_price) AS min_sales,
        MAX(ss_ext_sales_price) AS max_sales,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_ext_wholesale_cost BETWEEN 200 AND 3000
      AND ss_ext_tax < 500
      AND ss_list_price >= 10
      AND ss_quantity > 0
    GROUP BY ss_store_sk
),
overall_avg AS (
    SELECT AVG(ss_ext_sales_price) AS overall_avg_sales
    FROM store_sales
    WHERE ss_ext_wholesale_cost > 500
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_division_id,
    a.total_sales,
    a.avg_profit,
    a.min_sales,
    a.max_sales,
    a.sales_cnt,
    o.overall_avg_sales,
    a.total_sales / o.overall_avg_sales AS sales_vs_overall_avg
FROM store AS s
JOIN sales_agg AS a
    ON a.ss_store_sk = s.s_store_sk
CROSS JOIN overall_avg AS o
WHERE s.s_division_id = 1
  AND s.s_rec_start_date >= DATE '2000-01-01'
  AND s.s_floor_space > 8000000
  AND s.s_state = 'CA'
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_store_sk = s.s_store_sk
          AND ss.ss_net_profit < 0
    )
ORDER BY a.total_sales DESC
LIMIT 100
