SELECT
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    MAX(DATE_DIFF('day', d_promo_start.d_date, d_promo_end.d_date)) AS promo_duration_days,
    (SUM(cs.cs_net_paid) - SUM(cs.cs_ext_discount_amt)) AS net_after_discount,
    (SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0)) AS profit_margin,
    CASE
        WHEN SUM(cs.cs_quantity) > 0 THEN CAST(SUM(inv.inv_quantity_on_hand) AS double) / SUM(cs.cs_quantity)
        ELSE NULL
    END AS inventory_per_quantity
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name
HAVING
    SUM(cs.cs_net_paid) > 1000
    AND (SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0)) > 0.05
ORDER BY total_net_paid DESC
LIMIT 100
