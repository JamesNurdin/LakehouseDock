SELECT 
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(i.inv_quantity_on_hand) AS total_qty_on_hand,
    SUM(p_start.p_cost) AS total_promo_start_cost,
    SUM(p_end.p_cost) AS total_promo_end_cost,
    COUNT(DISTINCT s.s_store_sk) AS num_stores_closed,
    ROUND(SUM(cr.cr_net_loss) / NULLIF(SUM(i.inv_quantity_on_hand), 0), 2) AS loss_per_item,
    CASE 
        WHEN SUM(p_start.p_cost) > SUM(i.inv_quantity_on_hand) THEN 'HighPromo'
        ELSE 'LowPromo'
    END AS promo_intensity
FROM catalog_returns cr
JOIN date_dim d 
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN inventory i 
    ON i.inv_date_sk = d.d_date_sk
JOIN store s 
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p_start 
    ON p_start.p_start_date_sk = d.d_date_sk
JOIN promotion p_end 
    ON p_end.p_end_date_sk = d.d_date_sk
GROUP BY d.d_year, d.d_month_seq
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY d.d_year DESC, d.d_month_seq DESC
LIMIT 100
