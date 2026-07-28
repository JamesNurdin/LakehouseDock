WITH
    /* Base fact table */
    ws AS (
        SELECT *
        FROM web_sales
    )
SELECT
    wsit.web_name,
    wsit.web_state,
    s.s_store_name,
    ib.ib_lower_bound,
    COUNT(DISTINCT ws.ws_order_number)                AS order_cnt,
    SUM(ws.ws_net_profit)                           AS total_net_profit,
    SUM(sr.sr_net_loss)                             AS total_store_return_loss,
    SUM(cr.cr_net_loss)                             AS total_catalog_return_loss,
    SUM(wr.wr_net_loss)                             AS total_web_return_loss,
    ROW_NUMBER() OVER (PARTITION BY wsit.web_name ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
FROM ws
/* join household demographics for the billing side */
JOIN household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
/* join household demographics for the shipping side */
JOIN household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
/* join customer address for the billing side */
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
/* join customer address for the shipping side */
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
/* join web page */
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
/* join web site */
JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
/* income band for the billing household */
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
/* store returns – link through household demographics */
JOIN store_returns sr
  ON sr.sr_hdemo_sk = hd_bill.hd_demo_sk
/* store details */
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
/* catalog returns – refunded household side */
JOIN catalog_returns cr
  ON cr.cr_refunded_hdemo_sk = hd_ship.hd_demo_sk
/* catalog returns – refunded address side */
JOIN customer_address ca_cr_refunded
  ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
/* web returns – link through order number */
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
/* web returns – web page */
JOIN web_page wp_wr
  ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
/* web returns – refunded household */
JOIN household_demographics hd_wr_refunded
  ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
/* web returns – refunded address */
JOIN customer_address ca_wr_refunded
  ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
GROUP BY
    wsit.web_name,
    wsit.web_state,
    s.s_store_name,
    ib.ib_lower_bound
ORDER BY
    total_net_profit DESC,
    wsit.web_name
LIMIT 100
