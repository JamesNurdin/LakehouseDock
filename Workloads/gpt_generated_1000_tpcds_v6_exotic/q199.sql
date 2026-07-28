WITH base AS (
    SELECT
        ss.ss_net_paid            AS store_net_paid,
        ss.ss_net_profit          AS store_net_profit,
        ws.ws_net_paid            AS web_net_paid,
        ws.ws_net_profit          AS web_net_profit,
        cr.cr_net_loss            AS catalog_return_loss,
        wr.wr_net_loss            AS web_return_loss,
        d1.d_date                 AS transact_date,
        p.p_channel_email,
        s.s_state,
        ca1.ca_location_type,
        w.w_gmt_offset
    FROM store_sales ss
    JOIN date_dim d1          ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN time_dim t1          ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN customer c1         ON ss.ss_customer_sk = c1.c_customer_sk
    JOIN customer_demographics cd1 ON ss.ss_cdemo_sk = cd1.cd_demo_sk
    JOIN customer_address ca1     ON ss.ss_addr_sk = ca1.ca_address_sk
    JOIN store s             ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p         ON ss.ss_promo_sk = p.p_promo_sk
    /* web sales and its related dimensions */
    JOIN web_sales ws        ON ws.ws_sold_date_sk = d1.d_date_sk
                               AND ws.ws_sold_time_sk = t1.t_time_sk
    JOIN promotion p_ws      ON ws.ws_promo_sk = p_ws.p_promo_sk   -- same promotion table, re‑used
    JOIN warehouse w         ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp         ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we         ON ws.ws_web_site_sk = we.web_site_sk
    /* web returns linked to the same order */
    JOIN web_returns wr      ON ws.ws_order_number = wr.wr_order_number
    JOIN date_dim d2          ON wr.wr_returned_date_sk = d2.d_date_sk
    JOIN time_dim t2          ON wr.wr_returned_time_sk = t2.t_time_sk
    /* catalog returns – linked through the common date/time dimension */
    JOIN catalog_returns cr  ON cr.cr_returned_date_sk = d1.d_date_sk
                               AND cr.cr_returned_time_sk = t1.t_time_sk
    JOIN warehouse w_cr      ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    JOIN customer_address ca2 ON cr.cr_refunded_addr_sk = ca2.ca_address_sk
    WHERE d1.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND p.p_channel_email = 'Y'
      AND s.s_state = 'CA'
      AND ca1.ca_location_type = 'apartment'
      AND w.w_gmt_offset BETWEEN -5.00 AND -4.00
)
SELECT
    p_channel_email,
    s_state,
    AVG(total_net_profit) AS avg_total_net_profit
FROM (
    SELECT
        p_channel_email,
        s_state,
        (store_net_paid + web_net_paid) - (catalog_return_loss + web_return_loss) AS total_net_profit
    FROM base
) t
GROUP BY p_channel_email, s_state
HAVING AVG(total_net_profit) > 10000
ORDER BY avg_total_net_profit DESC
LIMIT 10
