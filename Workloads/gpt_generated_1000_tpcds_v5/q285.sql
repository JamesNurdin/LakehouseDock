WITH
    /* Base catalog returns */
    base_cr AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_return_amount,
            cr.cr_order_number,
            cr.cr_catalog_page_sk,
            cr.cr_refunded_customer_sk,
            cr.cr_refunded_hdemo_sk,
            cr.cr_returning_customer_sk,
            cr.cr_returning_hdemo_sk,
            cr.cr_reason_sk
        FROM tpcds.catalog_returns cr
    )
SELECT
    d_ret.d_year,
    d_ret.d_quarter_name,
    r.r_reason_desc,
    cp.cp_department,
    COALESCE(p.p_promo_name, 'No Promotion') AS promo_name,
    SUM(base_cr.cr_return_amount)                          AS total_catalog_return_amount,
    SUM(ws.ws_net_profit)                                 AS total_web_sales_profit,
    SUM(sr.sr_net_loss)                                   AS total_store_return_loss,
    SUM(wr.wr_net_loss)                                   AS total_web_return_loss,
    COUNT(DISTINCT ws.ws_order_number)                    AS web_orders,
    COUNT(DISTINCT base_cr.cr_order_number)               AS catalog_returns_count
FROM base_cr
JOIN tpcds.catalog_page cp
  ON base_cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.date_dim d_ret
  ON base_cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN tpcds.customer c_refunded
  ON base_cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN tpcds.household_demographics hd_refunded
  ON base_cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN tpcds.customer c_returning
  ON base_cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN tpcds.household_demographics hd_returning
  ON base_cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN tpcds.reason r
  ON base_cr.cr_reason_sk = r.r_reason_sk
/* Web sales linked through the same return date */
JOIN tpcds.web_sales ws
  ON ws.ws_sold_date_sk = d_ret.d_date_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
LEFT JOIN tpcds.promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.customer c_bill
  ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN tpcds.household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.customer c_ship
  ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN tpcds.household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
/* Web returns for the same orders */
JOIN tpcds.web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN tpcds.web_page wp_wr
  ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
JOIN tpcds.reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
/* Store returns that happened on the same day */
JOIN tpcds.store_returns sr
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN tpcds.customer c_sr
  ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN tpcds.household_demographics hd_sr
  ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN tpcds.reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
/* Inventory for the same day */
JOIN tpcds.inventory inv
  ON inv.inv_date_sk = d_ret.d_date_sk
/* Income band for the refunded household */
JOIN tpcds.income_band ib
  ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_quarter_name,
    r.r_reason_desc,
    cp.cp_department,
    COALESCE(p.p_promo_name, 'No Promotion')
ORDER BY
    d_ret.d_year DESC,
    total_web_sales_profit DESC
LIMIT 100
