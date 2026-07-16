SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_net_loss,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_quarter_name,
    w.w_warehouse_name,
    w.w_city,
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    p.p_discount_active,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY cr.cr_return_amount DESC) AS return_rank_in_store,
    COUNT(*) OVER (PARTITION BY w.w_warehouse_name) AS returns_per_warehouse
FROM catalog_returns AS cr
JOIN date_dim AS d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN warehouse AS w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store AS s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion AS p
    ON p.p_start_date_sk = d_ret.d_date_sk
WHERE cr.cr_return_amount > 0
  AND p.p_end_date_sk >= d_ret.d_date_sk
ORDER BY cr.cr_return_amount DESC
LIMIT 100
