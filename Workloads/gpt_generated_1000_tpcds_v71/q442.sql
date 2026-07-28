WITH cr AS (
        SELECT *
        FROM catalog_returns
    )
SELECT
    s.s_store_name,
    r.r_reason_desc,
    hd_ref.hd_buy_potential AS refunded_buy_potential,
    hd_ret.hd_buy_potential AS returning_buy_potential,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_returns,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(ws.ws_net_profit) AS total_web_profit,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
        ELSE (SUM(ws.ws_net_profit) - SUM(sr.sr_return_amt_inc_tax) - SUM(cr.cr_net_loss)) / SUM(ss.ss_ext_sales_price)
    END AS profit_margin_ratio
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN household_demographics hd_sales
    ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN customer_address ca_sales
    ON ss.ss_addr_sk = ca_sales.ca_address_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_store_sk = s.s_store_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN cr
    ON cr.cr_returning_hdemo_sk = hd_sales.hd_demo_sk
    AND cr.cr_returning_addr_sk = ca_sales.ca_address_sk
JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_bill_hdemo_sk = hd_ref.hd_demo_sk
    AND ws.ws_bill_addr_sk = ca_ref.ca_address_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE s.s_state = 'CA'
GROUP BY
    s.s_store_name,
    r.r_reason_desc,
    hd_ref.hd_buy_potential,
    hd_ret.hd_buy_potential
ORDER BY total_store_sales DESC
LIMIT 100
