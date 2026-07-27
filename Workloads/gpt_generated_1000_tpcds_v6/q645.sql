/*
Goal: Identify the top customers by total shipping cost across catalog and web sales, categorizing their catalog shipping cost, and ranking them using window functions while applying multiple business filters.
*/
WITH cs_agg AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_ext_ship_cost) AS sum_ship_cost,
        SUM(cs_ext_list_price) AS sum_list_price,
        COUNT(*) AS cs_order_cnt,
        CASE WHEN SUM(cs_ext_ship_cost) > 1000 THEN 'High' ELSE 'Low' END AS ship_cost_category
    FROM catalog_sales
    WHERE cs_ext_ship_cost > 100                         -- predicate 1
      AND cs_ext_list_price BETWEEN 500 AND 10000       -- predicate 2
      AND cs_quantity > 1                               -- predicate 3
      AND cs_sold_date_sk BETWEEN 2450000 AND 2455000  -- predicate 4 (surrogate date key)
      AND cs_net_profit > 0                             -- predicate 5
    GROUP BY cs_bill_customer_sk
),
ws_agg AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        ws_web_page_sk,
        SUM(ws_ext_ship_cost) AS ws_sum_ship_cost,
        SUM(ws_net_profit) AS ws_sum_profit,
        COUNT(*) AS ws_order_cnt
    FROM web_sales
    WHERE ws_ext_ship_cost > 100                         -- predicate 6
      AND ws_ext_list_price < 8000                       -- predicate 7
      AND ws_quantity > 1                                -- predicate 8
      AND ws_sold_date_sk BETWEEN 2450000 AND 2455000   -- predicate 9 (surrogate date key)
      AND ws_net_profit > 0                              -- predicate 10
    GROUP BY ws_bill_customer_sk, ws_web_page_sk
)
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cs.sum_ship_cost,
    cs.ship_cost_category,
    ws.ws_sum_ship_cost,
    ws.ws_sum_profit,
    wp.wp_image_count,
    wp.wp_max_ad_count,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.sum_ship_cost DESC) AS rn_ship_cost,
    RANK() OVER (ORDER BY (cs.sum_ship_cost + ws.ws_sum_ship_cost) DESC) AS total_ship_cost_rank,
    (cs.sum_ship_cost + ws.ws_sum_ship_cost) AS total_ship_cost
FROM cs_agg cs
JOIN customer c ON cs.customer_sk = c.c_customer_sk
JOIN ws_agg ws ON ws.customer_sk = c.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE c.c_birth_year BETWEEN 1950 AND 1990                     -- predicate 11
  AND c.c_current_hdemo_sk IN (2821, 6121, 2373)                -- predicate 12
  AND wp.wp_image_count >= 2                                   -- predicate 13
  AND wp.wp_rec_end_date >= DATE '2000-01-01'                  -- predicate 14 (date column)
  AND wp.wp_max_ad_count <= 3                                 -- predicate 15
ORDER BY total_ship_cost DESC
LIMIT 100
