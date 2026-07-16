SELECT
    s.s_state,
    d.d_year,
    CASE WHEN d.d_month_seq <= 6 THEN 'First Half' ELSE 'Second Half' END AS half_year,
    p.p_promo_name,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_active_discount_cost,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_returns,
    SUM(wr.wr_return_amt) / NULLIF(SUM(i.inv_quantity_on_hand), 0) AS return_inventory_ratio
FROM
    date_dim d
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2015 AND 2020
    AND s.s_state IS NOT NULL
    AND p.p_discount_active = 'Y'
GROUP BY
    s.s_state,
    d.d_year,
    CASE WHEN d.d_month_seq <= 6 THEN 'First Half' ELSE 'Second Half' END,
    p.p_promo_name
HAVING
    SUM(i.inv_quantity_on_hand) > 1000
ORDER BY
    s.s_state,
    d.d_year,
    half_year,
    p.p_promo_name
