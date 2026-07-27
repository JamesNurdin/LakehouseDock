WITH catalog_state_sales AS (
    SELECT ca.ca_state AS state,
           SUM(cs.cs_net_paid_inc_tax) AS total_sales,
           COUNT(*) AS order_cnt
    FROM   catalog_sales cs
    JOIN   customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN   ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE  sm.sm_code = 'AIR'
    GROUP BY ca.ca_state
),
store_state_sales AS (
    SELECT ca.ca_state AS state,
           SUM(ss.ss_net_paid_inc_tax) AS total_sales,
           COUNT(*) AS order_cnt
    FROM   store_sales ss
    JOIN   customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN   time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE  td.t_hour BETWEEN 9 AND 17
    GROUP BY ca.ca_state
),
combined AS (
    SELECT state, total_sales, order_cnt, 'catalog' AS source FROM catalog_state_sales
    UNION ALL
    SELECT state, total_sales, order_cnt, 'store'   AS source FROM store_state_sales
)
SELECT state,
       source,
       total_sales,
       order_cnt,
       ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_sales DESC) AS sales_rank
FROM   combined
ORDER BY source, total_sales DESC
LIMIT 100
