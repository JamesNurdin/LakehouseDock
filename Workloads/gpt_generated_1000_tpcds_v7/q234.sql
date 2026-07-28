WITH ws AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_order_number,
        ws.ws_net_profit
    FROM tpcds.web_sales ws
), sr AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_ticket_number,
        sr.sr_net_loss
    FROM tpcds.store_returns sr
)
SELECT
    d_sold.d_year AS year,
    s.s_store_name AS store_name,
    p.p_promo_name AS promotion_name,
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_net_loss) AS total_store_loss,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets
FROM ws
JOIN tpcds.date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.time_dim t_sold
  ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN tpcds.date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN tpcds.item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN tpcds.web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN tpcds.promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_date_sk = d_sold.d_date_sk
JOIN tpcds.income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN sr
  ON sr.sr_returned_date_sk = d_sold.d_date_sk
 AND sr.sr_item_sk = i.i_item_sk
JOIN tpcds.household_demographics hd_ret
  ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
JOIN tpcds.customer_address ca_ret
  ON sr.sr_addr_sk = ca_ret.ca_address_sk
JOIN tpcds.store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN tpcds.reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.time_dim t_ret
  ON sr.sr_return_time_sk = t_ret.t_time_sk
WHERE d_sold.d_year = 2001
GROUP BY
    d_sold.d_year,
    s.s_store_name,
    p.p_promo_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY
    d_sold.d_year,
    s.s_store_name,
    p.p_promo_name
