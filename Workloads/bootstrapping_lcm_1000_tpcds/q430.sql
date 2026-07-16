WITH agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        sm.sm_carrier,
        s.s_store_name,
        s.s_state,
        wp_c.wp_url AS creation_url,
        wp_a.wp_url AS access_url,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS unique_orders
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp_c ON wp_c.wp_creation_date_sk = d.d_date_sk
    JOIN web_page wp_a ON wp_a.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year >= 2000
    GROUP BY
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        sm.sm_carrier,
        s.s_store_name,
        s.s_state,
        wp_c.wp_url,
        wp_a.wp_url
)
SELECT
    d_year,
    d_month_seq,
    sm_type,
    sm_carrier,
    s_store_name,
    s_state,
    creation_url,
    access_url,
    total_return_amount,
    total_return_quantity,
    avg_net_loss,
    unique_orders,
    CASE
        WHEN d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter_label,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS yearly_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
