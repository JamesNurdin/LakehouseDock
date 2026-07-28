WITH base AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_net_loss,
        sr.sr_return_time_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_net_loss,
        ws.ws_sold_time_sk,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_net_profit,
        wr.wr_returned_time_sk,
        wr.wr_order_number,
        wr.wr_reason_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_refunded_cdemo_sk,
        wr.wr_refunded_hdemo_sk
    FROM catalog_returns cr
    JOIN store_returns sr
        ON sr.sr_return_time_sk = cr.cr_returned_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = cr.cr_returned_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = cr.cr_returned_time_sk
        AND wr.wr_order_number = ws.ws_order_number
)
SELECT
    s.s_store_name,
    ws_site.web_name,
    t.t_hour,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(ws.ws_net_profit) AS total_web_sales_profit,
    COUNT(DISTINCT c_ref.c_customer_sk) AS unique_customers,
    AVG(ib.ib_upper_bound) AS avg_income_upper_bound
FROM catalog_returns cr
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w1
    ON cr.cr_warehouse_sk = w1.w_warehouse_sk
JOIN reason r1
    ON cr.cr_reason_sk = r1.r_reason_sk
JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
LEFT JOIN income_band ib
    ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr
    ON sr.sr_return_time_sk = t.t_time_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r2
    ON sr.sr_reason_sk = r2.r_reason_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN warehouse w2
    ON ws.ws_warehouse_sk = w2.w_warehouse_sk
JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = t.t_time_sk
    AND wr.wr_order_number = ws.ws_order_number
JOIN reason r3
    ON wr.wr_reason_sk = r3.r_reason_sk
WHERE NOT EXISTS (
    SELECT 1 FROM store_returns sr2
    WHERE sr2.sr_customer_sk = c_ref.c_customer_sk
)
GROUP BY
    s.s_store_name,
    ws_site.web_name,
    t.t_hour
ORDER BY
    total_web_sales_profit DESC
LIMIT 100
