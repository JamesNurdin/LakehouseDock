SELECT
    td.t_hour,
    CASE
        WHEN hd_ss.hd_income_band_sk >= 10 THEN 'High Income'
        ELSE 'Low Income'
    END AS income_category,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
FROM time_dim td
JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN household_demographics hd_ws_bill
    ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN customer_address ca_ws_bill
    ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN household_demographics hd_ws_ship
    ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN customer_address ca_ws_ship
    ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = td.t_time_sk
JOIN household_demographics hd_cr_refunded
    ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
JOIN customer_address ca_cr_refunded
    ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
JOIN household_demographics hd_cr_returning
    ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
JOIN customer_address ca_cr_returning
    ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE td.t_hour BETWEEN 8 AND 20
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = ss.ss_sold_date_sk
      )
GROUP BY
    td.t_hour,
    CASE
        WHEN hd_ss.hd_income_band_sk >= 10 THEN 'High Income'
        ELSE 'Low Income'
    END
ORDER BY td.t_hour
LIMIT 100
