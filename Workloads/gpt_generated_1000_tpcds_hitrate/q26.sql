WITH catalog_filtered AS (
  SELECT cs.cs_order_number,
         cs.cs_net_profit,
         cs.cs_warehouse_sk
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE regexp_like(cp.cp_description, '\\d{4}')
    AND cp.cp_type LIKE 'A%'
    AND EXISTS (
        SELECT 1
        FROM customer_address ca
        WHERE ca.ca_address_sk = cs.cs_bill_addr_sk
          AND ca.ca_state = 'TX'
    )
),
web_filtered AS (
  SELECT ws.ws_order_number
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_url LIKE '%.html'
    AND regexp_extract(wp.wp_url, '([^/]+)\\.html$', 1) LIKE 'promo%'
),
intersect_orders AS (
  SELECT cs_order_number FROM catalog_filtered
  INTERSECT
  SELECT ws_order_number FROM web_filtered
)
SELECT w.w_warehouse_name,
       SUM(cf.cs_net_profit) AS total_net_profit,
       COUNT(DISTINCT cf.cs_order_number) AS order_cnt
FROM catalog_filtered cf
JOIN intersect_orders i ON cf.cs_order_number = i.cs_order_number
JOIN warehouse w ON cf.cs_warehouse_sk = w.w_warehouse_sk
GROUP BY w.w_warehouse_name
ORDER BY total_net_profit DESC
LIMIT 100
