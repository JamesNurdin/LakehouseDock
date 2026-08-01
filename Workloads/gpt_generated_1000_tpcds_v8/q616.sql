WITH
  -- Store sales enriched with its dimensions (date, time, household, address, income band)
  store_sales_enriched AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_hdemo_sk,
      ss.ss_addr_sk,
      ss.ss_store_sk,
      ss.ss_net_paid,
      ss.ss_quantity,
      d_sold.d_year                     AS year,
      t_sold.t_hour                     AS hour,
      ca.ca_state                       AS state,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM store_sales ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),

  -- Web sales enriched; note that date_dim and household_demographics are joined twice under different aliases
  web_sales_enriched AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_ship_date_sk,
      ws.ws_item_sk,
      ws.ws_bill_hdemo_sk,
      ws.ws_ship_hdemo_sk,
      ws.ws_bill_addr_sk,
      ws.ws_ship_addr_sk,
      ws.ws_web_page_sk,
      ws.ws_ship_mode_sk,
      ws.ws_warehouse_sk,
      ws.ws_net_paid,
      ws.ws_ext_list_price,
      d_sold.d_year                 AS sold_year,
      d_ship.d_year                 AS ship_year,
      t_sold.t_hour                 AS sold_hour,
      hd_bill.hd_income_band_sk     AS bill_income_band_sk,
      hd_ship.hd_income_band_sk     AS ship_income_band_sk,
      ca_bill.ca_state              AS bill_state,
      ca_ship.ca_state              AS ship_state,
      ib_bill.ib_lower_bound        AS bill_income_low,
      ib_ship.ib_upper_bound        AS ship_income_up
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN income_band ib_bill ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
    JOIN income_band ib_ship ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  ),

  -- Store returns enriched (date and time dimensions)
  store_returns_enriched AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_quantity,
      sr.sr_net_loss,
      d_ret.d_year                AS return_year,
      t_ret.t_hour                AS return_hour
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
  ),

  -- Call‑center enriched (open and close dates as years)
  call_center_enriched AS (
    SELECT
      cc.cc_call_center_id,
      cc.cc_name,
      cc.cc_state,
      cc.cc_gmt_offset,
      d_open.d_year   AS open_year,
      d_close.d_year  AS close_year,
      cc.cc_employees,
      cc.cc_sq_ft
    FROM call_center cc
    JOIN date_dim d_open  ON cc.cc_open_date_sk  = d_open.d_date_sk
    JOIN date_dim d_close ON cc.cc_closed_date_sk = d_close.d_date_sk
  ),

  -- A tiny computed set that will be cross‑joined (acts as a flag)
  extra_flag AS (
    SELECT 1 AS flag
  ),

  -- Base join that brings all enriched facts together; note the use of two aliases for date_dim and household_demographics
  base_joined AS (
    SELECT
      COALESCE(ss.year, ws.sold_year)               AS year,
      COALESCE(ss.hour, ws.sold_hour)               AS hour,
      COALESCE(ss.state, ws.bill_state)            AS state,
      cc.cc_name                                    AS call_center_name,
      ss.ss_net_paid                                AS store_net_paid,
      ws.ws_net_paid                                AS web_net_paid,
      ws.ws_web_page_sk                             AS web_page_sk,
      ss.ss_quantity                                AS store_quantity,
      CASE WHEN ws.ws_ext_list_price > (
            SELECT MAX(ws2.ws_ext_list_price)
            FROM web_sales ws2
            WHERE ws2.ws_sold_date_sk = ss.ss_sold_date_sk
          ) THEN 1 ELSE 0 END                     AS high_price_flag,
      sr.sr_net_loss                               AS return_loss,
      ef.flag                                       AS extra_flag
    FROM store_sales_enriched ss
    FULL JOIN web_sales_enriched ws
      ON ss.ss_ticket_number = ws.ws_order_number
    LEFT JOIN call_center_enriched cc
      ON ss.year = cc.open_year               -- join on year as a proxy
    LEFT JOIN store_returns_enriched sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
    CROSS JOIN extra_flag ef
  ),

  -- Aggregation with Cube producing subtotals
  agg_all AS (
    SELECT
      year,
      hour,
      state,
      call_center_name,
      extra_flag,
      SUM(store_net_paid)            AS total_store_net_paid,
      SUM(web_net_paid)              AS total_web_net_paid,
      COUNT(DISTINCT web_page_sk)    AS distinct_web_pages,
      SUM(DISTINCT store_quantity)   AS distinct_store_quantity,
      AVG(high_price_flag)           AS high_price_flag_ratio,
      SUM(return_loss)               AS total_return_loss
    FROM base_joined
    GROUP BY CUBE (year, hour, state, call_center_name, extra_flag)
  ),

  -- Same aggregation but filter out rows where store net paid is negative (these will be removed by EXCEPT)
  agg_excluded AS (
    SELECT
      year,
      hour,
      state,
      call_center_name,
      extra_flag,
      SUM(store_net_paid)            AS total_store_net_paid,
      SUM(web_net_paid)              AS total_web_net_paid,
      COUNT(DISTINCT web_page_sk)    AS distinct_web_pages,
      SUM(DISTINCT store_quantity)   AS distinct_store_quantity,
      AVG(high_price_flag)           AS high_price_flag_ratio,
      SUM(return_loss)               AS total_return_loss
    FROM base_joined
    WHERE store_net_paid < 0               -- rows to be excluded
    GROUP BY CUBE (year, hour, state, call_center_name, extra_flag)
  )

SELECT *
FROM agg_all
EXCEPT
SELECT *
FROM agg_excluded
ORDER BY year NULLS LAST, state
LIMIT 100
