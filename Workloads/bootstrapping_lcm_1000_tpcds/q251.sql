SELECT
    d_sold.d_year AS sale_year,
    i.i_category AS item_category,
    i.i_brand AS item_brand,
    s.s_state AS store_state,
    p.p_promo_name AS promo_name,
    COUNT(*) AS total_sales_cnt,
    SUM(cs.cs_sales_price) AS total_sales_price,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amt,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN cs.cs_ext_discount_amt ELSE 0 END) AS promo_discount_total,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    SUM(cs.cs_net_paid) - SUM(cs.cs_ext_tax) AS net_paid_excluding_tax,
    MIN(d_ship.d_date) AS first_ship_date,
    MAX(d_promo_end.d_date) AS promo_end_latest,
    SUM(CASE WHEN d_sold.d_month_seq BETWEEN 1 AND 3 THEN cs.cs_quantity ELSE 0 END) AS qty_q1,
    SUM(CASE WHEN d_sold.d_month_seq BETWEEN 4 AND 6 THEN cs.cs_quantity ELSE 0 END) AS qty_q2,
    SUM(CASE WHEN d_sold.d_month_seq BETWEEN 7 AND 9 THEN cs.cs_quantity ELSE 0 END) AS qty_q3,
    SUM(CASE WHEN d_sold.d_month_seq BETWEEN 10 AND 12 THEN cs.cs_quantity ELSE 0 END) AS qty_q4
FROM date_dim d_sold
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
   AND p.p_item_sk = i.i_item_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
  AND d_sold.d_year BETWEEN 2000 AND 2005
GROUP BY d_sold.d_year, i.i_category, i.i_brand, s.s_state, p.p_promo_name
HAVING SUM(cs.cs_sales_price) > 10000
ORDER BY total_sales_cnt DESC
LIMIT 100
