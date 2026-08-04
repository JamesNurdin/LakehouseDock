WITH date_filtered AS (
  SELECT d_date_sk, d_year, d_quarter_name, d_current_quarter
  FROM date_dim
  WHERE d_year = 2001
    AND d_quarter_name = 'Q1'
    AND d_current_quarter = 'Y'
)
SELECT
  ws.ws_order_number,
  ws.ws_sold_date_sk,
  d.d_year,
  w.w_warehouse_id,
  w.w_state,
  hd.hd_income_band_sk,
  td.t_am_pm,
  SUM(ws.ws_net_paid) AS total_net_paid,
  AVG(ws.ws_ext_discount_amt) AS avg_discount,
  COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
  MIN(ws.ws_sales_price) AS min_sales_price,
  MAX(ws.ws_sales_price) AS max_sales_price,
  (
    SELECT SUM(wr2.wr_return_amt)
    FROM web_returns wr2
    WHERE wr2.wr_order_number = ws.ws_order_number
  ) AS total_web_return_amt,
  u.val AS price_or_discount,
  COUNT(*) FILTER (WHERE u.val = ws.ws_ext_discount_amt) AS discount_occurrences
FROM web_sales ws
JOIN date_filtered d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN store_returns sr
  ON sr.sr_returned_date_sk = d.d_date_sk
  AND sr.sr_return_time_sk = td.t_time_sk
  AND sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
  AND wr.wr_returned_time_sk = td.t_time_sk
  AND wr.wr_order_number = ws.ws_order_number
  AND wr.wr_item_sk = ws.ws_item_sk
CROSS JOIN UNNEST(ARRAY[ws.ws_ext_discount_amt, ws.ws_ext_list_price]) AS u(val)
WHERE w.w_state = 'CA'
  AND w.w_warehouse_sq_ft > 500000
  AND hd.hd_income_band_sk = 8
  AND td.t_am_pm = 'PM'
  AND EXISTS (
      SELECT 1 FROM store_returns sr2
      WHERE sr2.sr_ticket_number = ws.ws_order_number
        AND sr2.sr_net_loss > 0
  )
GROUP BY
  ws.ws_order_number,
  ws.ws_sold_date_sk,
  d.d_year,
  w.w_warehouse_id,
  w.w_state,
  hd.hd_income_band_sk,
  td.t_am_pm,
  ws.ws_ext_discount_amt,
  ws.ws_ext_list_price,
  u.val
HAVING SUM(ws.ws_net_paid) > 100000
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
