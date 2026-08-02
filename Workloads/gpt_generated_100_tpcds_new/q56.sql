WITH base AS (
    SELECT
        s.s_store_id,
        s.s_state,
        cc.cc_name,
        p.p_promo_name,
        td.t_hour,
        SUM(ss.ss_net_paid) AS total_store_sales,
        AVG(cs.cs_net_paid) AS avg_catalog_sales,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        MIN(ws.ws_net_paid) AS min_web_paid,
        MAX(cr.cr_net_loss) AS max_return_loss,
        (
            SELECT SUM(ws2.ws_net_paid)
            FROM web_sales ws2
            WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
        ) AS customer_total_web_paid
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE cc.cc_state = 'CA'
      AND s.s_state = 'CA'
      AND we.web_state = 'CA'
      AND p.p_promo_name = 'Holiday Sale'
      AND td.t_hour BETWEEN 12 AND 14
      AND p.p_promo_sk IN (SELECT ss_promo_sk FROM store_sales WHERE ss_quantity > 5)
    GROUP BY s.s_store_id, s.s_state, cc.cc_name, p.p_promo_name, td.t_hour, c.c_customer_sk
)
SELECT *
FROM base
ORDER BY total_store_sales DESC
LIMIT 100
