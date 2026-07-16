SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    cp.cp_department,
    cp.cp_catalog_page_number,
    p.p_promo_name,
    p.p_discount_active,
    d_ret.d_year AS return_year,
    d_ret.d_quarter_name AS return_quarter,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_fee) AS total_fee,
    COUNT(*) AS num_returns,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    d_page_start.d_date AS page_start_date,
    d_page_end.d_date AS page_end_date,
    d_ret.d_date AS return_date,
    d_promo_end.d_date AS promo_end_date
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND d_ret.d_year >= 2020
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    cp.cp_department,
    cp.cp_catalog_page_number,
    p.p_promo_name,
    p.p_discount_active,
    d_ret.d_year,
    d_ret.d_quarter_name,
    d_page_start.d_date,
    d_page_end.d_date,
    d_ret.d_date,
    d_promo_end.d_date
ORDER BY total_net_loss DESC
LIMIT 100
