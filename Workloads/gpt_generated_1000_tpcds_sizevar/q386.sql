WITH
  -- Store sales base (joined to several dimensions)
  ss AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_store_sk,
      ss.ss_hdemo_sk,
      ss.ss_addr_sk,
      ss.ss_ext_sales_price,
      ss.ss_quantity,
      ss.ss_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca1 ON ss.ss_addr_sk = ca1.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 1915
  ),

  -- Store returns linked to returns reasons
  sr AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_amt,
      sr.sr_return_quantity,
      sr.sr_reason_sk
    FROM store_returns sr
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON sr.sr_return_time_sk = t2.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d2.d_year = 1915
  ),

  -- Web sales base (joined to ship mode and address dimensions)
  ws AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_ship_mode_sk,
      ws.ws_ext_sales_price,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_bill_addr_sk,
      ws.ws_ship_addr_sk,
      ws.ws_bill_hdemo_sk,
      ws.ws_ship_hdemo_sk
    FROM web_sales ws
    JOIN date_dim d3 ON ws.ws_sold_date_sk = d3.d_date_sk
    JOIN time_dim t3 ON ws.ws_sold_time_sk = t3.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d3.d_year = 1915
  ),

  -- Web returns linked to returns reasons
  wr AS (
    SELECT
      wr.wr_order_number,
      wr.wr_return_amt,
      wr.wr_reason_sk
    FROM web_returns wr
    JOIN date_dim d4 ON wr.wr_returned_date_sk = d4.d_date_sk
    JOIN time_dim t4 ON wr.wr_returned_time_sk = t4.t_time_sk
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE d4.d_year = 1915
  ),

  -- Income band information
  ib AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
  ),

  -- Household demographics enriched with income band
  hd_full AS (
    SELECT hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_buy_potential
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),

  -- Ticket numbers that appear both in store sales and store returns
  common_tickets AS (
    SELECT ss_ticket_number FROM ss
    INTERSECT
    SELECT sr_ticket_number FROM sr
  )

SELECT
  d.d_year,
  s.s_state,
  SUM(ss.ss_ext_sales_price) AS total_store_sales,
  SUM(CASE WHEN sr.sr_return_amt > 0 THEN sr.sr_return_amt ELSE 0 END) AS total_store_returns,
  SUM(ws.ws_ext_sales_price) AS total_web_sales,
  SUM(CASE WHEN wr.wr_return_amt > 0 THEN wr.wr_return_amt ELSE 0 END) AS total_web_returns,
  COUNT(DISTINCT common_tickets.ss_ticket_number) AS common_ticket_count
FROM date_dim d
JOIN ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN wr ON wr.wr_order_number = ws.ws_order_number
JOIN hd_full hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
JOIN customer_address ca3 ON ws.ws_ship_addr_sk = ca3.ca_address_sk
JOIN common_tickets ON common_tickets.ss_ticket_number = ss.ss_ticket_number
WHERE d.d_year = 1915
GROUP BY d.d_year, s.s_state
ORDER BY total_store_sales DESC
LIMIT 100
