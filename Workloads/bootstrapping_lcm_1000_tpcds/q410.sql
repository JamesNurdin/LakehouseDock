SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_quantity,
    cs.cs_sales_price,
    (cs.cs_quantity * cs.cs_sales_price) AS cs_total_sales,
    ws.ws_order_number,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ws.ws_quantity,
    ws.ws_sales_price,
    (ws.ws_quantity * ws.ws_sales_price) AS ws_total_sales,
    (cs.cs_quantity * cs.cs_sales_price) - (ws.ws_quantity * ws.ws_sales_price) AS sales_diff,
    d_sold.d_year AS cs_sold_year,
    d_ship.d_year AS cs_ship_year,
    d_ws_ship.d_year AS ws_ship_year,
    p.p_promo_name,
    p.p_discount_active,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    s.s_state,
    s.s_city
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_sold.d_date_sk
    AND ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
WHERE cs.cs_quantity > 0
  AND ws.ws_quantity > 0
  AND p.p_discount_active = 'Y'
ORDER BY cs.cs_net_paid DESC
LIMIT 100
