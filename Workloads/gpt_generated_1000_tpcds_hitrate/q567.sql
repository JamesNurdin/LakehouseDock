WITH joined_data AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_return_quantity,
        sr.sr_net_loss AS sr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss AS wr_net_loss,
        sm.sm_type,
        ws.web_state,
        wp.wp_web_page_id,
        -- scalar sub‑query: avg return amount for the same ship mode
        (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
        ) AS avg_return_amount_by_ship
    FROM date_dim d
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN customer c
        ON c.c_customer_sk = cr.cr_returning_customer_sk
    WHERE d.d_year = 2001
      AND c.c_birth_country = 'ARUBA'
      AND sm.sm_type = 'AIR'
      AND cr.cr_return_amount > 100
      AND sr.sr_return_quantity >= 2
      AND wr.wr_return_amt < 500
      AND ws.web_state = 'CA'
)
SELECT
    jd.c_customer_id,
    jd.c_first_name,
    jd.c_last_name,
    jd.c_birth_country,
    jd.sm_type,
    jd.web_state,
    SUM(COALESCE(jd.cr_net_loss, 0) + COALESCE(jd.sr_net_loss, 0) + COALESCE(jd.wr_net_loss, 0)) AS total_net_loss,
    CASE
        WHEN SUM(COALESCE(jd.cr_net_loss, 0) + COALESCE(jd.sr_net_loss, 0) + COALESCE(jd.wr_net_loss, 0)) > 5000 THEN 'HIGH'
        ELSE 'MEDIUM'
    END AS loss_category,
    AVG(jd.avg_return_amount_by_ship) OVER (PARTITION BY jd.sm_type) AS avg_return_amt_by_ship_mode,
    ROW_NUMBER() OVER (PARTITION BY jd.c_birth_country ORDER BY SUM(COALESCE(jd.cr_net_loss, 0) + COALESCE(jd.sr_net_loss, 0) + COALESCE(jd.wr_net_loss, 0)) DESC) AS rn_by_country
FROM joined_data jd
GROUP BY
    jd.c_customer_id,
    jd.c_first_name,
    jd.c_last_name,
    jd.c_birth_country,
    jd.sm_type,
    jd.web_state,
    jd.avg_return_amount_by_ship
HAVING SUM(COALESCE(jd.cr_net_loss, 0) + COALESCE(jd.sr_net_loss, 0) + COALESCE(jd.wr_net_loss, 0)) > 1000
ORDER BY total_net_loss DESC
