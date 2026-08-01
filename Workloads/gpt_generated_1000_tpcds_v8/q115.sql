WITH catalog_agg AS (
    SELECT
        sm.sm_type AS category,
        d.d_fy_year AS fy_year,
        SUM(cr.cr_net_loss) AS net_loss,
        COUNT(*) AS cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1915
      AND d.d_fy_quarter_seq = 13
      AND cr.cr_return_quantity > 1
      AND sm.sm_carrier = 'UPS'
      AND s.s_number_employees >= 250
      AND wp.wp_type = 'Content'
    GROUP BY sm.sm_type, d.d_fy_year
),
web_agg AS (
    SELECT
        wp.wp_type AS category,
        d.d_fy_year AS fy_year,
        SUM(wr.wr_net_loss) AS net_loss,
        COUNT(*) AS cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1915
      AND d.d_fy_quarter_seq = 13
      AND wr.wr_return_quantity > 0
      AND wr.wr_fee > 0
      AND wp.wp_type = 'Content'
      AND wp.wp_url LIKE 'http%'
    GROUP BY wp.wp_type, d.d_fy_year
),
combined AS (
    SELECT category, fy_year, net_loss, cnt FROM catalog_agg
    UNION ALL
    SELECT category, fy_year, net_loss, cnt FROM web_agg
)
SELECT
    category,
    fy_year,
    SUM(net_loss) AS total_net_loss,
    SUM(cnt) AS total_cnt,
    AVG(net_loss) AS avg_net_loss_per_row
FROM combined
GROUP BY category, fy_year
HAVING SUM(net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
