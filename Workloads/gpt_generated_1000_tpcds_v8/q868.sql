WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_ext_wholesale_cost > 1000
      AND cs_ext_ship_cost BETWEEN 500 AND 3000
      AND cs_quantity >= 1
      AND cs_net_paid_inc_ship_tax > 500
      AND cs_sold_date_sk BETWEEN 2450000 AND 2452000
      AND cs_list_price < 5000
),
ws_filtered AS (
    SELECT *
    FROM web_sales
    WHERE ws_wholesale_cost < 100
      AND ws_quantity >= 1
      AND ws_net_paid_inc_tax > 200
      AND ws_sold_date_sk BETWEEN 2450000 AND 2452000
      AND ws_list_price < 5000
      AND ws_ext_discount_amt > 0
)
SELECT
    cp.cp_department,
    w.w_state,
    c.c_birth_country,
    COUNT(DISTINCT cs.cs_order_number)          AS orders_cnt,
    SUM(cs.cs_ext_sales_price)                  AS total_sales,
    AVG(ws.ws_net_paid)                         AS avg_web_net_paid,
    MIN(cs.cs_ext_wholesale_cost)               AS min_wholesale_cost,
    MAX(cs.cs_ext_ship_cost)                    AS max_ship_cost,
    (
        SELECT AVG(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_ext_sales_price > 0
    )                                           AS overall_avg_sales_price
FROM cs_sample cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
WHERE c.c_customer_sk IN (
        SELECT cs_bill_customer_sk FROM catalog_sales
        INTERSECT
        SELECT ws_bill_customer_sk FROM web_sales
    )
  AND c.c_preferred_cust_flag = 'Y'
  AND w.w_gmt_offset BETWEEN -5 AND 5
  AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_order_number = cs.cs_order_number
          AND ws2.ws_net_paid < 0
    )
  AND EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_department = cp.cp_department
          AND cp2.cp_catalog_number = cp.cp_catalog_number
    )
GROUP BY cp.cp_department, w.w_state, c.c_birth_country
HAVING COUNT(*) > 10
ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
