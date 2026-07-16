SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    d_ship.d_month_seq AS ship_month_seq,
    p.p_promo_name,
    s.s_store_name,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    CASE
        WHEN SUM(cs.cs_net_paid) = 0 THEN 0
        ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid)
    END AS profit_to_paid_ratio,
    MIN(d_start.d_date) AS promo_start_date,
    MAX(d_end.d_date) AS promo_end_date
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
WHERE
    p.p_discount_active = 'Y'
    AND s.s_state = 'CA'
    AND d_sold.d_year BETWEEN 2020 AND 2022
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq,
    p.p_promo_name,
    s.s_store_name
HAVING
    SUM(cs.cs_net_paid) > 10000
ORDER BY
    total_net_paid DESC
LIMIT 100
