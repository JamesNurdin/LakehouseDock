WITH sales_by_center AS (
  SELECT
    cc.cc_call_center_id AS call_center_id,
    cc.cc_division_name AS division_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_list_price) AS total_ext_list_price,
    COUNT(cs.cs_order_number) AS order_cnt
  FROM call_center cc
  LEFT JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
       AND cs.cs_coupon_amt > 500
       AND cs.cs_ext_list_price > 1500
       AND cs.cs_ship_customer_sk IN (5482003, 189276, 3662153)
  WHERE
    cc.cc_state = 'CA'               -- predicate 1
    AND cc.cc_hours = '8AM-8AM'       -- predicate 2
    AND cc.cc_class = 'large'         -- predicate 3
    AND cc.cc_gmt_offset BETWEEN -5 AND 5  -- predicate 4
    AND cc.cc_country = 'United States'    -- predicate 5
    AND cc.cc_division IS NOT NULL          -- predicate 6
  GROUP BY cc.cc_call_center_id, cc.cc_division_name
)
SELECT
  division_name,
  AVG(total_net_paid) AS avg_net_paid,
  SUM(order_cnt) AS total_orders
FROM sales_by_center
WHERE total_ext_list_price > 2000               -- second‑level filter
GROUP BY division_name
HAVING AVG(total_net_paid) > 10000               -- having filter
ORDER BY avg_net_paid DESC
LIMIT 10
