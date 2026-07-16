SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    s.s_store_name,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    MAX(cs.cs_sales_price) AS max_sales_price,
    MIN(cs.cs_wholesale_cost) AS min_wholesale_cost,
    SUM(CASE WHEN d_ship.d_weekend = 'Y' THEN cs.cs_net_paid_inc_ship_tax ELSE 0 END) AS weekend_ship_sales,
    SUM(CASE WHEN d_wp_access.d_date >= DATE '2020-01-01' THEN cs.cs_ext_sales_price ELSE 0 END) AS sales_at_access_date,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    p.p_cost
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sold.d_year = 2020
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND wp.wp_type = 'home'
  AND d_promo_start.d_date <= d_sold.d_date
  AND d_promo_end.d_date >= d_sold.d_date
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    s.s_store_name,
    s.s_state,
    p.p_cost
HAVING SUM(cs.cs_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
