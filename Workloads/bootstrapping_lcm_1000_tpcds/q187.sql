SELECT
    d_start.d_year AS promo_year,
    d_start.d_month_seq AS promo_month,
    i.i_category AS item_category,
    i.i_brand AS item_brand,
    COUNT(DISTINCT s.s_store_id) AS store_count,
    COUNT(DISTINCT wp.wp_web_page_id) AS page_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_response_target) AS avg_response_target,
    SUM(i.i_wholesale_cost) AS total_wholesale_cost,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    MAX(d_end.d_date) AS promo_end_date,
    MIN(d_access.d_date) AS earliest_page_access_date
FROM promotion p
INNER JOIN item i
    ON p.p_item_sk = i.i_item_sk
INNER JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
INNER JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d_start.d_date_sk
INNER JOIN web_page wp
    ON wp.wp_creation_date_sk = d_start.d_date_sk
INNER JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_start.d_year = 2023
    AND i.i_category = 'Home'
    AND s.s_state = 'CA'
GROUP BY
    d_start.d_year,
    d_start.d_month_seq,
    i.i_category,
    i.i_brand
HAVING SUM(p.p_cost) > 1000
ORDER BY
    d_start.d_year,
    d_start.d_month_seq,
    i.i_category,
    i.i_brand
