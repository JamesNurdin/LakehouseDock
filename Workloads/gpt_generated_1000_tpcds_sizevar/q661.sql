WITH
  sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_ship_mode_sk,
      ws.ws_net_paid_inc_tax,
      ws.ws_ext_sales_price,
      d.d_year,
      sm.sm_type,
      CASE WHEN ws.ws_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS price_category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2002
      AND sm.sm_type = 'AIR'
      AND ws.ws_net_paid_inc_tax > 500
  ),
  returns AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_returned_date_sk,
      sr.sr_store_sk,
      sr.sr_return_amt,
      d.d_year,
      r.r_reason_desc,
      CASE WHEN sr.sr_return_amt > 200 THEN 'Big' ELSE 'Small' END AS return_size
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND r.r_reason_desc LIKE '%damaged%'
  )
SELECT
  d.d_year,
  sm.sm_type,
  r.r_reason_desc,
  COUNT(DISTINCT s.ws_order_number) AS num_orders,
  SUM(s.ws_ext_sales_price) AS total_sales,
  AVG(s.ws_net_paid_inc_tax) AS avg_paid,
  MIN(s.ws_ext_sales_price) AS min_sale,
  MAX(s.ws_ext_sales_price) AS max_sale,
  SUM(CASE WHEN s.price_category = 'High' THEN s.ws_ext_sales_price ELSE 0 END) AS high_sales,
  COUNT(r.sr_ticket_number) AS num_returns,
  SUM(r.sr_return_amt) AS total_returns
FROM sales s
JOIN returns r ON s.ws_sold_date_sk = r.sr_returned_date_sk
JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
JOIN ship_mode sm ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store st ON r.sr_store_sk = st.s_store_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
WHERE st.s_store_sk IN (
        SELECT s1.s_store_sk FROM store s1 WHERE s1.s_state = 'CA'
        INTERSECT
        SELECT sr1.sr_store_sk FROM store_returns sr1 WHERE sr1.sr_return_amt > 150
      )
  AND cc.cc_state = 'TX'
  AND d.d_month_seq BETWEEN 1200 AND 1211
GROUP BY GROUPING SETS (
        (d.d_year, sm.sm_type),
        (d.d_year, r.r_reason_desc)
      )
ORDER BY d.d_year DESC, total_sales DESC
LIMIT 100
