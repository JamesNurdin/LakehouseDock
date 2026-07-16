SELECT 
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    s.s_city AS city,
    s.s_state AS state,
    dr_ret.d_year AS return_year,
    dr_ret.d_month_seq AS return_month,
    p.p_promo_id AS promo_id,
    p.p_promo_name AS promo_name,
    COUNT(*) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(CASE WHEN sr.sr_return_quantity > 1 THEN sr.sr_return_amt ELSE 0 END) AS multi_item_return_amount,
    CASE 
        WHEN SUM(sr.sr_return_amt) > 10000 THEN 'High'
        WHEN SUM(sr.sr_return_amt) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS return_amount_category
FROM store_returns sr
JOIN date_dim dr_ret 
    ON sr.sr_returned_date_sk = dr_ret.d_date_sk
JOIN store s 
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dr_closed 
    ON s.s_closed_date_sk = dr_closed.d_date_sk
JOIN promotion p 
    ON p.p_start_date_sk = dr_ret.d_date_sk
JOIN date_dim dr_p_end 
    ON p.p_end_date_sk = dr_p_end.d_date_sk
WHERE dr_ret.d_date <= dr_p_end.d_date
  AND (dr_closed.d_date IS NULL OR dr_ret.d_date < dr_closed.d_date)
GROUP BY 
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    dr_ret.d_year,
    dr_ret.d_month_seq,
    p.p_promo_id,
    p.p_promo_name
ORDER BY total_return_amount DESC
LIMIT 100
