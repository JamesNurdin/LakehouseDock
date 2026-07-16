SELECT
    s.s_store_name,
    s.s_state,
    i.i_category,
    (d1.d_year - (d1.d_year % 5)) AS year_5yr_bucket,
    SUM(inv.inv_quantity_on_hand) AS total_quantity,
    AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(date_diff('day', d_start.d_date, d_end.d_date)) AS avg_promo_duration_days,
    CASE
        WHEN SUM(inv.inv_quantity_on_hand) > 2000 THEN 'Very High'
        WHEN SUM(inv.inv_quantity_on_hand) > 1000 THEN 'High'
        WHEN SUM(inv.inv_quantity_on_hand) BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS inventory_level
FROM store s
JOIN date_dim d1
    ON s.s_closed_date_sk = d1.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d1.d_date_sk
JOIN item i
    ON inv.inv_item_sk = i.i_item_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE d1.d_year >= 2010
GROUP BY
    s.s_store_name,
    s.s_state,
    i.i_category,
    (d1.d_year - (d1.d_year % 5))
