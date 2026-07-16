WITH aggregated AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        s.s_city,
        s.s_state,
        COUNT(DISTINCT wp.wp_type) AS distinct_web_page_types,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        MAX(wp.wp_image_count) AS max_image_count,
        (SUM(cr.cr_net_loss) / NULLIF(SUM(cr.cr_return_amount), 0)) AS net_loss_to_return_ratio
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE cr.cr_return_amount > 0
      AND d.d_year BETWEEN 2020 AND 2025
    GROUP BY
        d.d_year,
        d.d_quarter_name,
        s.s_city,
        s.s_state
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    d_year,
    d_quarter_name,
    s_city,
    s_state,
    distinct_web_page_types,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    max_image_count,
    net_loss_to_return_ratio,
    RANK() OVER (PARTITION BY d_year, d_quarter_name ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY d_year, d_quarter_name, total_net_loss DESC
LIMIT 100
