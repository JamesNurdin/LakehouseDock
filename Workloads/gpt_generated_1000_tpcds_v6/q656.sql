WITH filtered AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_returning_customer_sk,
        wr.wr_web_page_sk,
        wr.wr_reason_sk,
        wr.wr_return_amt,
        wr.wr_net_loss AS wr_net_loss,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        sm.sm_type,
        r.r_reason_desc,
        t.t_hour,
        ca.ca_state,
        c.c_customer_id,
        wp.wp_url,
        ws2.web_name
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws ON cr.cr_item_sk = ws.ws_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws2 ON ws.ws_web_site_sk = ws2.web_site_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN time_dim t2 ON wr.wr_returned_time_sk = t2.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND i.i_category = 'Sports'
      AND ca.ca_state IN ('CA', 'TX', 'NY')
)
SELECT
    c.c_customer_id,
    ca.ca_state,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    sm.sm_type,
    r.r_reason_desc,
    t.t_hour,
    SUM(cr.cr_return_amount)                                   AS total_catalog_return_amount,
    SUM(wr.wr_return_amt)                                      AS total_web_return_amount,
    SUM(cr.cr_net_loss + COALESCE(wr.wr_net_loss, 0))          AS total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id
                       ORDER BY SUM(cr.cr_return_amount + COALESCE(wr.wr_return_amt, 0)) DESC) AS rn
FROM catalog_returns cr
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws ON cr.cr_item_sk = ws.ws_item_sk
LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site ws2 ON ws.ws_web_site_sk = ws2.web_site_sk
LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
GROUP BY
    c.c_customer_id,
    ca.ca_state,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    sm.sm_type,
    r.r_reason_desc,
    t.t_hour
HAVING
    SUM(cr.cr_net_loss + COALESCE(wr.wr_net_loss, 0)) > (
        SELECT AVG(cr2.cr_net_loss + COALESCE(wr2.wr_net_loss, 0))
        FROM catalog_returns cr2
        JOIN reason r2 ON cr2.cr_reason_sk = r2.r_reason_sk
        LEFT JOIN web_returns wr2 ON cr2.cr_order_number = wr2.wr_order_number
        WHERE r2.r_reason_desc = r.r_reason_desc
    )
ORDER BY total_net_loss DESC
LIMIT 100
