SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    p.p_promo_id,
    cp.cp_department,
    d_return.d_year,
    d_return.d_month_seq,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS total_returns,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    p.p_cost AS promotion_cost
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_return.d_date BETWEEN d_page_start.d_date AND d_page_end.d_date
  AND d_return.d_date <= d_promo_end.d_date
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    p.p_promo_id,
    cp.cp_department,
    d_return.d_year,
    d_return.d_month_seq,
    p.p_cost
ORDER BY total_net_loss DESC, total_returns DESC
LIMIT 100
