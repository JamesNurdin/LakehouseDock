/* goal: Analyze combined catalog and web sales performance by item category, ship mode and hour of day, while incorporating related return amounts and demographic income band information. */
WITH
  -- Catalog sales enriched with dimensions
  cs_enriched AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_item_sk,
      cs.cs_ship_mode_sk,
      cs.cs_warehouse_sk,
      cs.cs_sold_time_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_ship_hdemo_sk,
      cs.cs_bill_addr_sk,
      cs.cs_ship_addr_sk,
      i.i_category,
      sm.sm_type,
      w.w_warehouse_name,
      t_cs.t_hour,
      hd_bill.hd_income_band_sk AS bill_income_band_sk,
      hd_ship.hd_income_band_sk AS ship_income_band_sk
    FROM catalog_sales cs
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  ),

  -- Web sales enriched with dimensions
  ws_enriched AS (
    SELECT
      ws.ws_order_number,
      ws.ws_net_paid,
      ws.ws_item_sk,
      ws.ws_ship_mode_sk,
      ws.ws_warehouse_sk,
      ws.ws_sold_time_sk,
      ws.ws_bill_hdemo_sk,
      ws.ws_ship_hdemo_sk,
      ws.ws_bill_addr_sk,
      ws.ws_ship_addr_sk,
      i.i_category,
      sm.sm_type,
      w.w_warehouse_name,
      t_ws.t_hour,
      hd_bill.hd_income_band_sk AS bill_income_band_sk,
      hd_ship.hd_income_band_sk AS ship_income_band_sk
    FROM web_sales ws
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  ),

  -- Store returns linked to the same item and time dimensions
  sr_enriched AS (
    SELECT
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_item_sk,
      sr.sr_return_time_sk,
      i.i_category,
      t_sr.t_hour,
      hd.hd_income_band_sk,
      ca.ca_address_sk
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  ),

  -- Web returns linked to web sales and dimensions
  wr_enriched AS (
    SELECT
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_item_sk,
      wr.wr_returned_time_sk,
      i.i_category,
      t_wr.t_hour,
      hd_ref.hd_income_band_sk AS refunded_income_band_sk,
      ca_ref.ca_address_sk AS refunded_addr_sk,
      hd_ret.hd_income_band_sk AS returning_income_band_sk,
      ca_ret.ca_address_sk AS returning_addr_sk,
      ws.ws_order_number
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
  )
SELECT
  cs.i_category,
  cs.sm_type,
  cs.t_hour,
  COUNT(DISTINCT cs.cs_order_number)            AS catalog_orders,
  SUM(cs.cs_net_paid)                           AS catalog_net_paid,
  COUNT(DISTINCT ws.ws_order_number)            AS web_orders,
  SUM(ws.ws_net_paid)                           AS web_net_paid,
  SUM(sr.sr_return_amt)                         AS store_returns_amount,
  SUM(wr.wr_return_amt)                         AS web_returns_amount,
  SUM(ib.ib_upper_bound - ib.ib_lower_bound)   AS income_band_range
FROM cs_enriched cs
LEFT JOIN ws_enriched ws   ON cs.cs_item_sk = ws.ws_item_sk
LEFT JOIN sr_enriched sr   ON cs.cs_item_sk = sr.sr_item_sk
LEFT JOIN wr_enriched wr   ON cs.cs_item_sk = wr.wr_item_sk
LEFT JOIN household_demographics hd_bill ON cs.bill_income_band_sk = hd_bill.hd_demo_sk
LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE cs.t_hour BETWEEN 8 AND 20
GROUP BY cs.i_category, cs.sm_type, cs.t_hour
ORDER BY (SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid)) DESC
LIMIT 100
