WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_net_profit,
        cr.cr_net_loss,
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_net_profit,
        wr.wr_net_loss,
        c.c_customer_id,
        cc.cc_state,
        cp.cp_catalog_page_number,
        p.p_channel_dmail,
        p.p_promo_id,
        wp.wp_type,
        r_cr.r_reason_desc AS cr_reason_desc,
        r_wr.r_reason_desc AS wr_reason_desc
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN call_center cc_ret
        ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
    LEFT JOIN catalog_page cp_ret
        ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    LEFT JOIN customer c_refund
        ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    LEFT JOIN customer c_return
        ON cr.cr_returning_customer_sk = c_return.c_customer_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
       AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN customer c_refund_wr
        ON wr.wr_refunded_customer_sk = c_refund_wr.c_customer_sk
    LEFT JOIN customer c_return_wr
        ON wr.wr_returning_customer_sk = c_return_wr.c_customer_sk
    LEFT JOIN web_page wp_ret
        ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
    LEFT JOIN customer c_webowner
        ON wp.wp_customer_sk = c_webowner.c_customer_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_catalog_page_number BETWEEN 1 AND 3
      AND p.p_channel_dmail = 'Y'
      AND wp.wp_type = 'order'
      AND r_cr.r_reason_desc = 'Damaged'
),
aggregated AS (
    SELECT
        c_customer_id,
        p_promo_id,
        SUM(cs_net_profit) AS total_catalog_net_profit,
        COALESCE(SUM(cr_net_loss), 0) AS total_catalog_net_loss,
        SUM(ws_net_profit) AS total_web_net_profit,
        COALESCE(SUM(wr_net_loss), 0) AS total_web_net_loss
    FROM joined_data
    GROUP BY c_customer_id, p_promo_id
),
final AS (
    SELECT
        c_customer_id,
        p_promo_id,
        (total_catalog_net_profit - total_catalog_net_loss + total_web_net_profit - total_web_net_loss) AS total_net_profit,
        RANK() OVER (PARTITION BY p_promo_id ORDER BY (total_catalog_net_profit - total_catalog_net_loss + total_web_net_profit - total_web_net_loss) DESC) AS profit_rank
    FROM aggregated
)
SELECT DISTINCT
    c_customer_id,
    p_promo_id,
    total_net_profit,
    profit_rank
FROM final
WHERE profit_rank <= 10
ORDER BY total_net_profit DESC
LIMIT 100
