WITH high_qty_items AS (
    SELECT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 10
    INTERSECT
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 5
)
SELECT
    i.i_category,
    d.d_month_seq,
    sm.sm_type,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(ss.ss_net_paid) AS total_store_sales,
    AVG(ws.ws_net_paid) AS avg_web_sales,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss ELSE 0 END) AS total_return_loss
FROM date_dim d
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
  AND cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
  AND inv.inv_date_sk = d.d_date_sk
  AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
  AND ws.ws_sold_date_sk = d.d_date_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_item_sk = i.i_item_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
WHERE d.d_year = 1999
  AND i.i_brand = 'Brand#12'
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'CA'
  AND we.web_country = 'United States'
  AND r.r_reason_desc = 'Customer Not Satisfied'
  AND i.i_item_sk IN (SELECT item_sk FROM high_qty_items)
GROUP BY ROLLUP (i.i_category, d.d_month_seq, sm.sm_type)
ORDER BY i.i_category, d.d_month_seq, sm.sm_type
LIMIT 100
