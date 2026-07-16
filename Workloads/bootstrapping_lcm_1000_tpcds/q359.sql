SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_quarter_name AS sold_quarter,
    d_ship.d_month_seq AS ship_month,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_quantity) AS avg_quantity,
    CASE
        WHEN SUM(cs.cs_net_paid) > 200000 THEN 'VERY HIGH'
        WHEN SUM(cs.cs_net_paid) > 100000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_paid) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS revenue_category
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN item i2
    ON p.p_item_sk = i2.i_item_sk
WHERE d_sold.d_year BETWEEN 1998 AND 2002
  AND p.p_discount_active = 'Y'
GROUP BY ROLLUP (
    d_sold.d_year,
    d_sold.d_quarter_name,
    d_ship.d_month_seq,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    s.s_state
)
HAVING SUM(cs.cs_net_paid) > 0
ORDER BY total_net_paid DESC
LIMIT 100
