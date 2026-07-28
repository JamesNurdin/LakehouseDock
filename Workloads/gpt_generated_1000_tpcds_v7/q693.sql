WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_ext_sales_price
    FROM tpcds.store_sales ss
)
SELECT
    c.c_customer_id,
    c_ship.c_customer_id AS ship_customer_id,
    ca.ca_city,
    hd.hd_buy_potential,
    ss_base.ss_net_profit AS store_net_profit,
    sr.sr_net_loss AS store_return_loss,
    cr.cr_return_amount AS catalog_return_amount,
    rp.r_reason_desc AS store_return_reason,
    cc.cc_name AS call_center_name,
    ws.ws_net_profit AS web_net_profit,
    ws_site.web_name AS web_site_name,
    cr_reason.r_reason_desc AS catalog_return_reason
FROM base_sales ss_base
JOIN tpcds.customer c
  ON ss_base.ss_customer_sk = c.c_customer_sk
JOIN tpcds.household_demographics hd
  ON ss_base.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.customer_address ca
  ON ss_base.ss_addr_sk = ca.ca_address_sk
LEFT JOIN tpcds.store_returns sr
  ON sr.sr_ticket_number = ss_base.ss_ticket_number
LEFT JOIN tpcds.reason rp
  ON sr.sr_reason_sk = rp.r_reason_sk
LEFT JOIN tpcds.catalog_returns cr
  ON cr.cr_returning_customer_sk = c.c_customer_sk
LEFT JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN tpcds.reason cr_reason
  ON cr.cr_reason_sk = cr_reason.r_reason_sk
LEFT JOIN tpcds.web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN tpcds.customer c_ship
  ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
LEFT JOIN tpcds.web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE ss_base.ss_sold_date_sk BETWEEN 2450815 AND 2451179
GROUP BY
    c.c_customer_id,
    c_ship.c_customer_id,
    ca.ca_city,
    hd.hd_buy_potential,
    ss_base.ss_net_profit,
    sr.sr_net_loss,
    cr.cr_return_amount,
    rp.r_reason_desc,
    cc.cc_name,
    ws.ws_net_profit,
    ws_site.web_name,
    cr_reason.r_reason_desc
HAVING SUM(ss_base.ss_ext_sales_price) > 10000
ORDER BY SUM(ss_base.ss_ext_sales_price) DESC
LIMIT 100
