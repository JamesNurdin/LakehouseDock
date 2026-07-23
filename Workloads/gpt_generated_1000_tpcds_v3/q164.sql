WITH joined AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_paid_inc_ship_tax,
    cr.cr_net_loss,
    sr.sr_net_loss,
    i.i_category,
    i.i_brand,
    cp.cp_department,
    sm.sm_type,
    hd_bill.hd_buy_potential AS hd_buy_potential_bill,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    td.t_hour
  FROM tpcds.web_sales ws
  JOIN tpcds.item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN tpcds.time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN tpcds.household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN tpcds.household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN tpcds.customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN tpcds.customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN tpcds.ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
  JOIN tpcds.catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
  JOIN tpcds.time_dim td_sr
    ON sr.sr_return_time_sk = td_sr.t_time_sk
  JOIN tpcds.income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
  i_category,
  i_brand,
  cp_department,
  sm_type,
  hd_buy_potential_bill,
  ib_lower_bound,
  ib_upper_bound,
  t_hour,
  COUNT(DISTINCT ws_order_number) AS num_sales_orders,
  SUM(ws_net_paid_inc_ship_tax) AS total_sales_amount,
  SUM(cr_net_loss) AS total_catalog_return_loss,
  SUM(sr_net_loss) AS total_store_return_loss
FROM joined
GROUP BY
  i_category,
  i_brand,
  cp_department,
  sm_type,
  hd_buy_potential_bill,
  ib_lower_bound,
  ib_upper_bound,
  t_hour
ORDER BY total_sales_amount DESC
LIMIT 100
