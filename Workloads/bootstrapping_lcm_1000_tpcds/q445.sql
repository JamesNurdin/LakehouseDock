SELECT
    d_return.d_year AS return_year,
    s.s_state AS store_state,
    CASE WHEN (d_return.d_month_seq % 2) = 0 THEN 'EvenMonth' ELSE 'OddMonth' END AS month_parity,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(wp.wp_image_count) AS avg_image_count,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
    SUM(
        CASE
            WHEN p.p_discount_active = 'Y' THEN cr.cr_return_amount * (1 - p.p_cost / 100)
            ELSE cr.cr_return_amount
        END
    ) AS adjusted_return_amount,
    MIN(d_access.d_day_name) AS first_access_day,
    MAX(d_promo_end.d_quarter_name) AS promo_end_quarter
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_return.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_return.d_year BETWEEN 2000 AND 2005
  AND s.s_state IS NOT NULL
  AND p.p_discount_active = 'Y'
GROUP BY
    d_return.d_year,
    s.s_state,
    CASE WHEN (d_return.d_month_seq % 2) = 0 THEN 'EvenMonth' ELSE 'OddMonth' END
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
