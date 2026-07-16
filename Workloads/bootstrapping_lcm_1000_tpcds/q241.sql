SELECT
    d_ret.d_date AS return_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    p.p_channel_tv,
    d_start.d_date AS promo_start_date,
    d_end.d_date   AS promo_end_date,
    d_store.d_date AS store_closed_date,
    SUM(sr.sr_return_amt)               AS total_return_amount,
    SUM(sr.sr_net_loss)                 AS total_net_loss,
    SUM(sr.sr_return_quantity)         AS total_return_qty,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    SUM(inv.inv_quantity_on_hand)       AS total_inventory_on_hand,
    COUNT(DISTINCT inv.inv_warehouse_sk) AS distinct_warehouses
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
GROUP BY
    d_ret.d_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    p.p_channel_tv,
    d_start.d_date,
    d_end.d_date,
    d_store.d_date
ORDER BY total_return_amount DESC
LIMIT 100
