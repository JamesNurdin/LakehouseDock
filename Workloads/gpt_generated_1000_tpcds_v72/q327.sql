WITH
    cr AS (
        SELECT
            cr.cr_warehouse_sk,
            cr.cr_ship_mode_sk,
            cr.cr_returned_time_sk,
            cr.cr_net_loss,
            cr.cr_refunded_hdemo_sk,
            cr.cr_refunded_cdemo_sk,
            cr.cr_refunded_addr_sk,
            cr.cr_returning_hdemo_sk,
            cr.cr_returning_cdemo_sk,
            cr.cr_returning_addr_sk
        FROM catalog_returns cr
    ),
    ws AS (
        SELECT *
        FROM web_sales
    ),
    wr AS (
        SELECT *
        FROM web_returns
    )
SELECT
    w.w_warehouse_name,
    sm_cr.sm_type AS ship_mode_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cr.cr_net_loss) AS catalog_return_loss,
    SUM(wr.wr_net_loss) AS web_return_loss,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    SUM(cr.cr_net_loss + wr.wr_net_loss + ws.ws_net_profit) AS total_contribution
FROM cr
JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN customer_demographics cd_return ON cr.cr_returning_cdemo_sk = cd_return.cd_demo_sk
JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN household_demographics hd_return ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
JOIN income_band ib ON hd_refund.hd_income_band_sk = ib.ib_income_band_sk

JOIN ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk

JOIN wr ON wr.wr_order_number = ws.ws_order_number
          AND wr.wr_item_sk = ws.ws_item_sk
JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
JOIN customer_address ca_wr_return ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
JOIN customer_demographics cd_wr_refund ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
JOIN customer_demographics cd_wr_return ON wr.wr_returning_cdemo_sk = cd_wr_return.cd_demo_sk
JOIN household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
JOIN household_demographics hd_wr_return ON wr.wr_returning_hdemo_sk = hd_wr_return.hd_demo_sk
JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
WHERE td_cr.t_hour BETWEEN 8 AND 17
GROUP BY
    w.w_warehouse_name,
    sm_cr.sm_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_contribution DESC
LIMIT 100
