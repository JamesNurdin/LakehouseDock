WITH filtered_returns AS (
    SELECT
        cr.cr_net_loss,
        wr.wr_net_loss,
        c_refunded.c_customer_sk,
        c_refunded.c_customer_id,
        c_refunded.c_salutation,
        c_refunded.c_first_name,
        c_refunded.c_last_name,
        cc.cc_name,
        cp.cp_description,
        w.w_city,
        we.web_name,
        we.web_class,
        w.w_state,
        ws.ws_quantity
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN income_band ib ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE r_cr.r_reason_id IN ('AAAAAAAABBAAAAAA', 'AAAAAAAEAAAAAAA')
      AND c_refunded.c_salutation = 'Mr.'
      AND ca_refunded.ca_gmt_offset = -7.00
      AND w.w_state = 'CA'
      AND we.web_class = 'B2C'
      AND ws.ws_quantity > 5
)
SELECT
    c_customer_id,
    c_salutation,
    c_first_name,
    c_last_name,
    cc_name AS call_center_name,
    cp_description AS catalog_page_desc,
    w_city AS warehouse_city,
    web_name AS web_site_name,
    total_loss,
    CASE WHEN total_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    loss_rank
FROM (
    SELECT
        c_customer_id,
        c_salutation,
        c_first_name,
        c_last_name,
        cc_name,
        cp_description,
        w_city,
        web_name,
        (cr_net_loss + wr_net_loss) AS total_loss,
        RANK() OVER (PARTITION BY c_customer_sk ORDER BY (cr_net_loss + wr_net_loss) DESC) AS loss_rank
    FROM filtered_returns
) t
WHERE loss_rank = 1
ORDER BY total_loss DESC
LIMIT 100
