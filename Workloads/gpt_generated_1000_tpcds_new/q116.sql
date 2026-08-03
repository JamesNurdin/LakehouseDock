WITH agg_store AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit
    FROM store_sales
    WHERE ss_quantity > 2
      AND ss_net_profit > 0
    GROUP BY ss_sold_date_sk, ss_sold_time_sk, ss_item_sk
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    sm.sm_ship_mode_id,
    sm.sm_code,
    td.t_hour,
    agg.total_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    CASE WHEN sm.sm_code = 'AIR' THEN 'Fast' ELSE 'Standard' END AS shipping_category,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_net_profit DESC) AS dept_profit_rank,
    SUM(cs.cs_ext_sales_price) OVER (PARTITION BY cp.cp_department ORDER BY td.t_hour ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_sales_sum
FROM agg_store agg
JOIN time_dim td ON agg.ss_sold_time_sk = td.t_time_sk
JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cp.cp_end_date_sk > 2451000
  AND sm.sm_code = 'AIR'
  AND td.t_hour BETWEEN 8 AND 17
  AND cs.cs_quantity >= 2
  AND agg.total_quantity > 5
  AND cs.cs_ext_sales_price > (
        SELECT AVG(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_quantity > 5
    )
ORDER BY cp.cp_department, dept_profit_rank
LIMIT 100
