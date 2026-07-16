SELECT
    d.d_current_quarter,
    s.s_state,
    CASE
        WHEN (d.d_month_seq % 3) = 1 THEN 'MonthGroup1'
        WHEN (d.d_month_seq % 3) = 2 THEN 'MonthGroup2'
        ELSE 'MonthGroup3'
    END AS month_group,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_tax) AS total_return_tax,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wp.wp_image_count * wp.wp_char_count) AS weighted_page_metric,
    CASE
        WHEN SUM(wr.wr_return_amt) > 50000 THEN 'HIGH'
        ELSE 'LOW'
    END AS return_amount_category
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2022
  AND s.s_state IS NOT NULL
  AND wp.wp_type = 'product'
GROUP BY
    d.d_current_quarter,
    s.s_state,
    (d.d_month_seq % 3)
HAVING SUM(wr.wr_return_amt) > 0
ORDER BY d.d_current_quarter, s.s_state
LIMIT 100
