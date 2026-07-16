SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    p.p_promo_name,
    s.s_state,
    ws.web_country,
    CASE
        WHEN cs.cs_quantity >= 10 THEN 'Bulk'
        ELSE 'Regular'
    END AS qty_category,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_ext_sales_price) / NULLIF(SUM(cs.cs_quantity), 0) AS avg_price_per_item,
    DATE_DIFF('day', MIN(d_promo_start.d_date), MAX(d_promo_end.d_date)) AS promo_duration_days,
    DATE_DIFF('day', MIN(d_store_closed.d_date), MIN(d_sold.d_date)) AS days_store_closed_to_sold,
    DATE_DIFF('day', MIN(d_sold.d_date), MAX(d_ship.d_date)) AS days_between_sold_and_ship,
    DATE_DIFF('day', MIN(d_web_open.d_date), MAX(d_web_close.d_date)) AS web_site_open_to_close_days
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s ON true
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_site ws ON true
JOIN date_dim d_web_open ON ws.web_open_date_sk = d_web_open.d_date_sk
JOIN date_dim d_web_close ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE d_sold.d_year >= 2020
  AND d_ship.d_date >= d_sold.d_date
  AND d_promo_start.d_date <= d_sold.d_date
  AND d_promo_end.d_date >= d_sold.d_date
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    s.s_state,
    ws.web_country,
    CASE
        WHEN cs.cs_quantity >= 10 THEN 'Bulk'
        ELSE 'Regular'
    END
HAVING COUNT(DISTINCT cs.cs_order_number) > 5
ORDER BY total_net_paid DESC
LIMIT 100
