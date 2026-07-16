SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS total_returns,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(p_start.p_cost) AS total_promo_start_cost,
    SUM(p_end.p_cost) AS total_promo_end_cost,
    AVG(p_start.p_response_target) AS avg_promo_start_response,
    AVG(p_end.p_response_target) AS avg_promo_end_response
FROM
    catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p_start
    ON p_start.p_start_date_sk = d.d_date_sk
JOIN promotion p_end
    ON p_end.p_end_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2020 AND 2022
    AND s.s_state = 'CA'
    AND p_start.p_discount_active = 'Y'
    AND p_end.p_discount_active = 'Y'
    AND inv.inv_quantity_on_hand > 0
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq
HAVING
    SUM(cr.cr_net_loss) > 5000
ORDER BY
    total_net_loss DESC
LIMIT 50
