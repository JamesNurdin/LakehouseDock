SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    d_sold.d_weekend AS weekend_flag,
    s.s_market_desc AS market,
    p.p_purpose AS promo_purpose,
    CASE WHEN ws.ws_quantity > 5 THEN 'high' ELSE 'low' END AS quantity_category,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(p.p_cost) AS total_promo_cost,
    (SUM(ws.ws_ext_sales_price) - SUM(p.p_cost)) / NULLIF(SUM(p.p_cost), 0) AS sales_to_cost_ratio,
    SUM(ws.ws_ext_discount_amt) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS discount_rate,
    DATE_DIFF('day', d_pstart.d_date, d_sold.d_date) AS days_from_promo_start,
    DATE_DIFF('day', d_sold.d_date, d_pend.d_date) AS days_until_promo_end
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_pstart ON p.p_start_date_sk = d_pstart.d_date_sk
JOIN date_dim d_pend ON p.p_end_date_sk = d_pend.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2022
  AND p.p_discount_active = 'Y'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_weekend,
    s.s_market_desc,
    p.p_purpose,
    CASE WHEN ws.ws_quantity > 5 THEN 'high' ELSE 'low' END,
    DATE_DIFF('day', d_pstart.d_date, d_sold.d_date),
    DATE_DIFF('day', d_sold.d_date, d_pend.d_date)
HAVING SUM(ws.ws_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
