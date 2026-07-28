WITH ws_detail AS (
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_sold_time_sk,
    ws.ws_ship_date_sk,
    ws.ws_item_sk,
    ws.ws_web_site_sk,
    ws.ws_promo_sk,
    ws.ws_bill_customer_sk,
    ws.ws_ship_customer_sk,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit,
    d_sold.d_year,
    d_sold.d_month_seq,
    t_sold.t_hour,
    p.p_promo_name,
    p.p_discount_active,
    w.web_name,
    c_bill.c_customer_id AS bill_cust_id,
    c_ship.c_customer_id AS ship_cust_id,
    cd_bill.cd_credit_rating AS bill_credit_rating,
    cd_ship.cd_credit_rating AS ship_credit_rating,
    ca_bill.ca_city AS bill_city,
    ca_ship.ca_city AS ship_city,
    inv.inv_quantity_on_hand
  FROM web_sales ws
  JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  LEFT JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
)
SELECT
  ws_detail.d_year,
  ws_detail.web_name,
  SUM(ws_detail.ws_quantity) AS total_units_sold,
  SUM(ws_detail.ws_net_paid) AS total_net_paid,
  SUM(ws_detail.ws_net_profit) AS total_net_profit,
  CASE
    WHEN SUM(ws_detail.ws_net_paid) = 0 THEN 0
    ELSE SUM(ws_detail.ws_net_profit) / SUM(ws_detail.ws_net_paid)
  END AS profit_margin,
  COUNT(DISTINCT ws_detail.ws_item_sk) AS distinct_items,
  COUNT(DISTINCT ws_detail.p_promo_name) AS promo_count,
  SUM(CASE WHEN ws_detail.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_discount_promo,
  CASE
    WHEN EXISTS (
      SELECT 1
      FROM store_returns sr
      JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
      JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
      JOIN customer c_ret ON sr.sr_customer_sk = c_ret.c_customer_sk
      WHERE d_ret.d_year = ws_detail.d_year
        AND r.r_reason_desc = 'Damaged'
    ) THEN 'Has Returns'
    ELSE 'No Returns'
  END AS return_indicator
FROM ws_detail
GROUP BY ws_detail.d_year, ws_detail.web_name
ORDER BY ws_detail.d_year DESC, total_net_paid DESC
LIMIT 100
