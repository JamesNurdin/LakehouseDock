SELECT
    d_return.d_year AS return_year,
    d_return.d_moy AS return_month,
    cp.cp_type,
    p.p_promo_name,
    CASE WHEN s.s_state = 'CA' THEN 'California' ELSE s.s_state END AS state_group,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_active_discount_cost,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_catalog_pages,
    MIN(d_cp_start.d_date) AS catalog_start_date,
    MAX(d_cp_end.d_date) AS catalog_end_date,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MAX(d_promo_end.d_date) AS promo_end_date,
    MIN(d_store_closed.d_date) AS store_closed_date
FROM catalog_page cp
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
GROUP BY
    d_return.d_year,
    d_return.d_moy,
    cp.cp_type,
    p.p_promo_name,
    CASE WHEN s.s_state = 'CA' THEN 'California' ELSE s.s_state END
ORDER BY total_net_loss DESC
LIMIT 100
