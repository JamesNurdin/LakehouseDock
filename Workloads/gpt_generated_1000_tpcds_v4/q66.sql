WITH ws AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_promo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk,
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship,
        ws.ws_ext_discount_amt,
        ws.ws_quantity
    FROM tpcds.web_sales ws
    WHERE ws.ws_net_paid_inc_ship IS NOT NULL
)
SELECT
    d.d_year,
    sm.sm_carrier,
    p.p_promo_name,
    ws_site.web_state,
    td.t_hour,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_quantity) AS total_qty,
    SUM(ws.ws_net_paid_inc_ship) AS total_net_paid,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amt
FROM ws
JOIN tpcds.date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN tpcds.ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN tpcds.customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN tpcds.web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
WHERE d.d_year = 2001
  AND sm.sm_carrier = 'UPS'
  AND ws_site.web_state = 'CA'
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY d.d_year, sm.sm_carrier, p.p_promo_name, ws_site.web_state, td.t_hour
HAVING SUM(ws.ws_net_paid_inc_ship) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
