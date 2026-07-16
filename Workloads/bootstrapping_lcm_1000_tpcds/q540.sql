SELECT
    (d_ret.d_year * 100 + d_ret.d_month_seq) AS year_month_key,
    d_ret.d_week_seq AS return_week,
    s.s_state,
    s.s_city,
    s.s_division_name,
    p.p_promo_name,
    wp.wp_type,
    d_creation.d_year AS creation_year,
    d_access.d_month_seq AS access_month,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN wr.wr_return_quantity > 1 THEN wr.wr_return_amt ELSE 0 END) AS multi_item_return_amount,
    MIN(d_start.d_date) AS promo_start_date,
    MAX(d_end.d_date) AS promo_end_date,
    date_diff('day', MIN(d_start.d_date), MAX(d_end.d_date)) AS promo_duration_days,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT s.s_store_id) AS num_stores
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_ret.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND wp.wp_type IN ('product', 'category')
GROUP BY
    (d_ret.d_year * 100 + d_ret.d_month_seq),
    d_ret.d_week_seq,
    s.s_state,
    s.s_city,
    s.s_division_name,
    p.p_promo_name,
    wp.wp_type,
    d_creation.d_year,
    d_access.d_month_seq
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
LIMIT 100
