SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_type,
    p.p_promo_id,
    p.p_promo_name,
    s.s_store_name,
    d_return.d_year AS return_year,
    d_return.d_month_seq AS return_month,
    d_page_start.d_year AS page_start_year,
    d_page_end.d_year AS page_end_year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_cnt
FROM catalog_page cp
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN promotion p
    ON d_return.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_type,
    p.p_promo_id,
    p.p_promo_name,
    s.s_store_name,
    d_return.d_year,
    d_return.d_month_seq,
    d_page_start.d_year,
    d_page_end.d_year
ORDER BY total_return_amount DESC
LIMIT 100
