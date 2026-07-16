SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    s.s_state,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(*) AS total_transactions,
    CASE
        WHEN SUM(cs.cs_ext_sales_price) > 0 THEN SUM(cs.cs_net_paid) / SUM(cs.cs_ext_sales_price)
        ELSE NULL
    END AS paid_to_sales_ratio,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MAX(d_promo_end.d_date) AS promo_end_date
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_sold.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
WHERE d_sold.d_year >= 1998
  AND p.p_discount_active = 'Y'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    s.s_state
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
