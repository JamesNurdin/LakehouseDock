SELECT
    s.s_store_name,
    s.s_state,
    cc.cc_name,
    cc.cc_state,
    d.d_date AS event_date,
    d.d_year,
    d.d_quarter_name,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_inventory_items,
    SUM(p.p_cost) AS total_promotion_cost,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promo_ids
FROM
    date_dim d
    INNER JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    INNER JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
        AND cc.cc_open_date_sk = d.d_date_sk
    INNER JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    INNER JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
        AND p.p_end_date_sk = d.d_date_sk
WHERE
    d.d_year = 2022
    AND s.s_state = 'CA'
    AND cc.cc_state = 'CA'
GROUP BY
    s.s_store_name,
    s.s_state,
    cc.cc_name,
    cc.cc_state,
    d.d_date,
    d.d_year,
    d.d_quarter_name
ORDER BY
    total_inventory_qty DESC
LIMIT 100
