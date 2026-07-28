WITH store_channel AS (
  SELECT
    'store' AS channel,
    s.s_store_id AS location_id,
    i.i_item_id AS item_id,
    t.t_hour AS hour_of_day,
    r.r_reason_desc AS reason_desc,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt_inc_tax) AS total_return,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_time_sk = t.t_time_sk
  LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_return_time_sk = t.t_time_sk
    AND sr.sr_store_sk = s.s_store_sk
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE t.t_hour BETWEEN 9 AND 17
    AND i.i_category = 'Electronics'
    AND s.s_state = 'CA'
    AND w.w_country = 'United States'
    AND cp.cp_catalog_number > 10
    AND r.r_reason_desc IN ('Damaged', 'Not as described')
    AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_brand = 'BrandX')
    AND EXISTS (
      SELECT 1 FROM store_returns sr2
      WHERE sr2.sr_store_sk = s.s_store_sk
        AND sr2.sr_net_loss > 200
    )
  GROUP BY s.s_store_id, i.i_item_id, t.t_hour, r.r_reason_desc
),
web_channel AS (
  SELECT
    'web' AS channel,
    w.w_warehouse_id AS location_id,
    i.i_item_id AS item_id,
    t.t_hour AS hour_of_day,
    r.r_reason_desc AS reason_desc,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(wr.wr_return_amt_inc_tax) AS total_return,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_tickets
  FROM web_sales ws
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_time_sk = t.t_time_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE t.t_hour BETWEEN 9 AND 17
    AND i.i_category = 'Electronics'
    AND w.w_country = 'United States'
    AND r.r_reason_desc IN ('Damaged', 'Not as described')
    AND ws.ws_sales_price > 20.0
    AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_brand = 'BrandX')
  GROUP BY w.w_warehouse_id, i.i_item_id, t.t_hour, r.r_reason_desc
)
SELECT
  channel,
  location_id,
  item_id,
  hour_of_day,
  reason_desc,
  SUM(total_sales) AS sum_sales,
  SUM(total_return) AS sum_return,
  SUM(total_inventory) AS sum_inventory,
  SUM(distinct_tickets) AS sum_distinct_tickets
FROM (
  SELECT * FROM store_channel
  UNION ALL
  SELECT * FROM web_channel
) AS combined
GROUP BY channel, location_id, item_id, hour_of_day, reason_desc
ORDER BY sum_sales DESC
LIMIT 100
