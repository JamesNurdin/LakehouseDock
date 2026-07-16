SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    d_start.d_year AS start_year,
    d_start.d_month_seq AS start_month_seq,
    d_end.d_year AS end_year,
    d_end.d_month_seq AS end_month_seq,
    p.p_promo_id,
    p.p_discount_active,
    s.s_store_id,
    s.s_state,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_start.d_date_sk
   AND p.p_end_date_sk = d_end.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
WHERE
    p.p_discount_active = 'Y'
    AND s.s_state = 'CA'
    AND cp.cp_type = 'Seasonal'
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    d_start.d_year,
    d_start.d_month_seq,
    d_end.d_year,
    d_end.d_month_seq,
    p.p_promo_id,
    p.p_discount_active,
    s.s_store_id,
    s.s_state
ORDER BY total_net_loss DESC
LIMIT 100
