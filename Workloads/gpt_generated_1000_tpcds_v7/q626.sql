WITH avg_ret AS (
   SELECT w.w_warehouse_sk,
          AVG(cr.cr_return_amount) AS avg_return_amount
   FROM catalog_returns cr
   JOIN warehouse w
     ON cr.cr_warehouse_sk = w.w_warehouse_sk
   GROUP BY w.w_warehouse_sk
)
SELECT
    ss.ss_ticket_number,
    ca.ca_city,
    cp.cp_department,
    cr.cr_return_amount,
    w_cr.w_warehouse_name,
    wp.wp_url,
    ws.ws_net_profit,
    CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_category,
    DENSE_RANK() OVER (PARTITION BY cp.cp_department ORDER BY cr.cr_return_amount DESC) AS return_rank,
    ar.avg_return_amount
FROM store_sales ss
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w_cr
  ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN avg_ret ar
  ON ar.w_warehouse_sk = w_cr.w_warehouse_sk
WHERE w_cr.w_street_name IN ('Elm Madison', 'Miller Broadway')
  AND cp.cp_catalog_number > 5
  AND wp.wp_image_count >= 4
  AND ca.ca_zip LIKE '12%'
  AND ws.ws_net_profit > 0
ORDER BY return_rank
LIMIT 100
