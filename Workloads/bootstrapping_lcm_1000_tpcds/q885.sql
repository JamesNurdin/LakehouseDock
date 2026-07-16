SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    cp.cp_catalog_page_id,
    cp.cp_description,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    AVG(p.p_cost) AS avg_promo_cost,
    MIN(d_return.d_date) AS first_return_date,
    MAX(d_return.d_date) AS last_return_date,
    MIN(d_store_closed.d_date) AS store_closed_date,
    MIN(d_cp_start.d_date) AS catalog_start_date,
    MAX(d_cp_end.d_date) AS catalog_end_date,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MAX(d_promo_end.d_date) AS promo_end_date
FROM store_returns sr
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN catalog_page cp
    ON d_return.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN promotion p
    ON d_return.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND sr.sr_return_quantity > 0
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    cp.cp_catalog_page_id,
    cp.cp_description
ORDER BY total_return_amount DESC
LIMIT 100
