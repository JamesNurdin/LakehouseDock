WITH
  return_data AS (
    SELECT
      w.w_warehouse_name AS warehouse,
      SUM(cr.cr_return_amount) AS total_amount,
      COUNT(*) AS transaction_cnt,
      CASE
        WHEN SUM(cr.cr_return_amount) > (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) THEN 'Above Avg'
        ELSE 'Below Avg'
      END AS amount_category,
      'Return' AS source
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'monthly'
      AND w.w_state = 'CA'
      AND w.w_warehouse_sk IN (
        SELECT cr3.cr_warehouse_sk
        FROM catalog_returns cr3
        WHERE cr3.cr_return_quantity > 5
      )
    GROUP BY w.w_warehouse_name
  ),
  sales_data AS (
    SELECT
      w.w_warehouse_name AS warehouse,
      SUM(ws.ws_net_paid) AS total_amount,
      COUNT(*) AS transaction_cnt,
      CASE
        WHEN SUM(ws.ws_net_paid) > (SELECT AVG(ws2.ws_net_paid) FROM web_sales ws2) THEN 'Above Avg'
        ELSE 'Below Avg'
      END AS amount_category,
      'Sale' AS source
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE wp.wp_autogen_flag = 'Y'
      AND ca.ca_state = 'CA'
      AND ws.ws_warehouse_sk IN (
        SELECT cr4.cr_warehouse_sk
        FROM catalog_returns cr4
        WHERE cr4.cr_return_quantity > 0
      )
    GROUP BY w.w_warehouse_name
  )
SELECT *
FROM return_data
UNION ALL
SELECT *
FROM sales_data
ORDER BY warehouse, source
