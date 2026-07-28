WITH joined_data AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year AS year,
        cr.cr_net_loss                     AS catalog_net_loss,
        sr.sr_net_loss                     AS store_net_loss,
        wr.wr_net_loss                     AS web_net_loss,
        sm.sm_type,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        p.p_promo_name,
        wp.wp_url
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    -- store returns part
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t_store ON sr.sr_return_time_sk = t_store.t_time_sk
    JOIN customer c_store ON sr.sr_customer_sk = c_store.c_customer_sk
    JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
    JOIN customer_address ca_store ON sr.sr_addr_sk = ca_store.ca_address_sk
    -- web returns part
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t_web ON wr.wr_returned_time_sk = t_web.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_web ON wr.wr_refunded_customer_sk = c_web.c_customer_sk
    JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
    JOIN customer_address ca_web ON wr.wr_refunded_addr_sk = ca_web.ca_address_sk
    WHERE d.d_year = 2002
      AND t.t_hour BETWEEN 9 AND 17
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc = 'Damaged'
      AND inv.inv_quantity_on_hand > 0
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    year,
    SUM(COALESCE(catalog_net_loss, 0) + COALESCE(store_net_loss, 0) + COALESCE(web_net_loss, 0)) AS total_loss,
    CASE
        WHEN SUM(COALESCE(catalog_net_loss, 0) + COALESCE(store_net_loss, 0) + COALESCE(web_net_loss, 0)) > 1000 THEN 'High'
        WHEN SUM(COALESCE(catalog_net_loss, 0) + COALESCE(store_net_loss, 0) + COALESCE(web_net_loss, 0)) > 500  THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    RANK() OVER (ORDER BY SUM(COALESCE(catalog_net_loss, 0) + COALESCE(store_net_loss, 0) + COALESCE(web_net_loss, 0)) DESC) AS loss_rank
FROM joined_data
GROUP BY c_customer_id, c_first_name, c_last_name, year
ORDER BY loss_rank
LIMIT 100
