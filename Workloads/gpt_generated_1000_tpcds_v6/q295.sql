WITH agg AS (
    SELECT
        s.s_store_id,
        web.web_site_id,
        d1.d_year,
        SUM(sr.sr_net_loss) AS store_return_loss,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(wr.wr_net_loss) AS web_return_loss,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN date_dim d1 ON cr.cr_returned_date_sk = d1.d_date_sk
    JOIN time_dim t1 ON cr.cr_returned_time_sk = t1.t_time_sk
    JOIN customer_demographics cd_cr_ref ON cr.cr_refunded_cdemo_sk = cd_cr_ref.cd_demo_sk
    JOIN customer_address ca_cr_ref ON cr.cr_refunded_addr_sk = ca_cr_ref.ca_address_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d1.d_date_sk
        AND sr.sr_return_time_sk = t1.t_time_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d1.d_date_sk
        AND ws.ws_sold_time_sk = t1.t_time_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
    JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d1.d_date_sk
        AND wr.wr_returned_time_sk = t1.t_time_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN customer_demographics cd_wr_ref ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
    JOIN customer_address ca_wr_ref ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
    JOIN customer_demographics cd_wr_ret ON wr.wr_returning_cdemo_sk = cd_wr_ret.cd_demo_sk
    JOIN customer_address ca_wr_ret ON wr.wr_returning_addr_sk = ca_wr_ret.ca_address_sk
    WHERE d1.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
      AND sm.sm_carrier = 'FEDEX'
      AND r_cr.r_reason_desc = 'Customer Not Satisfied'
      AND s.s_state = 'CA'
      AND web.web_name = 'Online Store'
      AND s.s_store_id IN (SELECT s2.s_store_id FROM store s2 WHERE s2.s_number_employees > 500)
    GROUP BY s.s_store_id, web.web_site_id, d1.d_year
)
SELECT
    a.d_year,
    AVG(a.total_loss) AS avg_total_loss,
    SUM(a.web_sales_profit) AS sum_total_profit,
    CASE
        WHEN SUM(a.total_loss) > 0 THEN 'Overall Profit'
        ELSE 'Overall Loss'
    END AS overall_flag
FROM (
    SELECT
        d_year,
        (store_return_loss + catalog_return_loss + web_return_loss) AS total_loss,
        web_sales_profit
    FROM agg
) a
WHERE a.total_loss > 0
GROUP BY a.d_year
ORDER BY avg_total_loss DESC
LIMIT 100
