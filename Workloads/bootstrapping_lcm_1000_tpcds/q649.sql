SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    cr.cr_item_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_fee,
    cr.cr_net_loss,
    p.p_promo_id,
    p.p_cost,
    p.p_discount_active,
    CASE
        WHEN d.d_month_seq = 12 THEN 'Holiday Season'
        ELSE 'Regular Season'
    END AS season_flag,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cr.cr_net_loss DESC) AS loss_rank,
    SUM(cr.cr_net_loss) OVER (PARTITION BY s.s_store_id) AS total_loss_per_store,
    COUNT(*) OVER (PARTITION BY s.s_store_id) AS returns_per_store
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
   AND p.p_end_date_sk = d.d_date_sk
WHERE cr.cr_net_loss > 0
ORDER BY total_loss_per_store DESC, s.s_store_id
LIMIT 100
