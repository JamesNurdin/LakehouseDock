WITH agg AS (
    SELECT
        dr.d_date,
        dr.d_year,
        dr.d_date_sk,
        sm.sm_type,
        cp.cp_department,
        ws.web_name,
        wp.wp_type,
        p.p_promo_name,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON p.p_start_date_sk = dr.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws ON ws.web_open_date_sk = dr.d_date_sk
    WHERE dr.d_year = 2001
      AND sm.sm_type = 'OVERNIGHT'
      AND cp.cp_department = 'Books'
      AND p.p_discount_active = 'Y'
      AND ws.web_country = 'United States'
      AND wp.wp_char_count > 1000
    GROUP BY
        dr.d_date,
        dr.d_year,
        dr.d_date_sk,
        sm.sm_type,
        cp.cp_department,
        ws.web_name,
        wp.wp_type,
        p.p_promo_name
)
SELECT
    a.d_date,
    a.d_year,
    a.sm_type,
    a.cp_department,
    a.web_name,
    a.wp_type,
    a.p_promo_name,
    a.total_net_loss,
    CASE WHEN a.total_net_loss > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_net_loss DESC) AS loss_rank,
    SUM(a.total_net_loss) OVER (PARTITION BY a.d_year ORDER BY a.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_year_loss,
    (SELECT COUNT(DISTINCT p2.p_promo_id)
     FROM promotion p2
     WHERE p2.p_start_date_sk <= a.d_date_sk
       AND p2.p_end_date_sk >= a.d_date_sk) AS active_promo_cnt
FROM agg a
ORDER BY a.d_date
LIMIT 100
