SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    i.inv_quantity_on_hand,
    i.inv_warehouse_sk,
    p.p_promo_name,
    p.p_discount_active,
    p.p_cost,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    s.s_tax_percentage,
    CASE
        WHEN p.p_discount_active = 'Y' THEN p.p_cost * 0.9
        ELSE p.p_cost
    END AS adjusted_promo_cost,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY i.inv_quantity_on_hand DESC) AS inv_qty_rank
FROM
    customer c
JOIN date_dim d
    ON c.c_first_shipto_date_sk = d.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2015 AND 2020
    AND i.inv_quantity_on_hand > 0
    AND p.p_discount_active = 'Y'
    AND s.s_state = 'CA'
ORDER BY
    d.d_date DESC,
    i.inv_quantity_on_hand DESC
LIMIT 100
