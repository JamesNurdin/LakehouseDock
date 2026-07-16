SELECT
    d.d_year,
    d.d_current_month,
    s.s_store_sk,
    s.s_store_name,
    SUM(cr.cr_return_amount)                             AS total_return_amount,
    SUM(cr.cr_return_quantity)                           AS total_return_quantity,
    SUM(cr.cr_return_tax)                                AS total_return_tax,
    SUM(cr.cr_net_loss)                                  AS total_net_loss,
    AVG(cr.cr_return_amount)                             AS avg_return_amount,
    SUM(i.inv_quantity_on_hand)                          AS total_inventory_quantity,
    COUNT(DISTINCT i.inv_item_sk)                        AS distinct_inventory_items,
    SUM(s.s_floor_space)                                 AS total_store_floor_space,
    COUNT(DISTINCT s.s_store_sk)                         AS distinct_closed_stores,
    SUM(CASE WHEN cr.cr_return_quantity > 5 
             THEN cr.cr_return_amount 
             ELSE 0 END)                                 AS high_quantity_return_amount,
    SUM(cr.cr_return_amount) / NULLIF(SUM(i.inv_quantity_on_hand), 0) AS return_per_inventory_quantity
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2022
GROUP BY
    d.d_year,
    d.d_current_month,
    s.s_store_sk,
    s.s_store_name
HAVING SUM(cr.cr_return_amount) > 0
ORDER BY d.d_year, d.d_current_month, s.s_store_sk
