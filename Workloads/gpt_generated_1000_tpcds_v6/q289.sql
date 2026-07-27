/*
Goal: Calculate warehouse‑level return and sales performance by return reason during business hours, 
filtering to US warehouses on avenues, high‑value returns, and product web pages. The query joins all
selected tables, applies multiple selective predicates, uses an EXISTS semi‑join, aggregates, 
filters groups with HAVING, includes a DISTINCT count, and orders the results.
*/
SELECT
    w.w_warehouse_name,
    r.r_reason_desc,
    td.t_hour,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    SUM(cr.cr_return_amount)           AS total_return_amount,
    SUM(cs.cs_ext_sales_price)         AS total_sales_amount,
    AVG(cs.cs_net_profit)              AS avg_sales_profit,
    MIN(ws.ws_net_profit)              AS min_web_profit,
    MAX(ws.ws_net_profit)              AS max_web_profit
FROM catalog_returns cr
JOIN catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk      = cs.cs_item_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
 AND cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN time_dim td
  ON cr.cr_returned_time_sk = td.t_time_sk
 AND cs.cs_sold_time_sk    = td.t_time_sk
 AND ws.ws_sold_time_sk    = td.t_time_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
WHERE w.w_country      = 'United States'
  AND w.w_street_type = 'Avenue'
  AND r.r_reason_desc LIKE '%time%'
  AND td.t_hour BETWEEN 9 AND 17
  AND cr.cr_return_amount > 100.00
  AND cs.cs_quantity       > 5
  AND ws.ws_quantity       > 2
  AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
          AND wp.wp_type = 'Product'
      )
GROUP BY w.w_warehouse_name, r.r_reason_desc, td.t_hour
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
