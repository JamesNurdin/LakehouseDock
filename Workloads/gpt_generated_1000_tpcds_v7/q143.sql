WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        ss.ss_net_profit,
        ss.ss_quantity,
        i.inv_quantity_on_hand,
        cr.cr_return_amount,
        wr.wr_net_loss,
        p.p_promo_name,
        cc.cc_name,
        cp.cp_description,
        r1.r_reason_desc
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r1 ON cr.cr_reason_sk = r1.r_reason_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND i.inv_quantity_on_hand > 0
      AND r1.r_reason_desc LIKE '%defect%'
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(ss_quantity) AS total_quantity_sold,
    SUM(inv_quantity_on_hand) AS total_inventory,
    SUM(cr_return_amount) AS total_catalog_return,
    SUM(wr_net_loss) AS total_web_return_loss,
    RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
FROM base
GROUP BY s_store_id, s_store_name, d_year
ORDER BY profit_rank
LIMIT 100
