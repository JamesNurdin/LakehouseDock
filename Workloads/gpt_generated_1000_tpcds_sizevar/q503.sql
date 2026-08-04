WITH order_intersection AS (
        SELECT ws_order_number FROM web_sales WHERE ws_quantity > 2
        INTERSECT
        SELECT ws_order_number FROM web_sales WHERE ws_ext_discount_amt > 0
    ),
    filtered_web AS (
        SELECT
            ws_order_number,
            ws_sold_date_sk,
            ws_ship_date_sk,
            ws_quantity,
            ws_sales_price,
            ws_ext_sales_price,
            ws_net_profit,
            ws_net_paid,
            ws_ship_mode_sk,
            ws_warehouse_sk,
            ws_promo_sk,
            ws_bill_addr_sk,
            ws_ship_addr_sk,
            ws_web_site_sk
        FROM web_sales
        TABLESAMPLE BERNOULLI (5)
        WHERE ws_quantity > 1
    )
SELECT
    ws.ws_web_site_sk,
    web.web_name,
    ship.sm_carrier,
    ware.w_state,
    promo.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS avg_profit,
    MIN(ws.ws_sold_date_sk) AS first_sold_date_sk,
    MAX(ws.ws_sold_date_sk) AS last_sold_date_sk
FROM filtered_web ws
JOIN order_intersection oi ON ws.ws_order_number = oi.ws_order_number
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN ship_mode ship ON ws.ws_ship_mode_sk = ship.sm_ship_mode_sk
JOIN warehouse ware ON ws.ws_warehouse_sk = ware.w_warehouse_sk
JOIN promotion promo ON ws.ws_promo_sk = promo.p_promo_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN store_returns sr ON sr.sr_addr_sk = ca.ca_address_sk
WHERE web.web_rec_start_date >= DATE '1999-01-01'
  AND web.web_rec_end_date <= DATE '2002-12-31'
  AND ship.sm_carrier = 'ZOUROS'
  AND ware.w_state = 'CA'
  AND ca.ca_state = 'TX'
  AND sr.sr_return_quantity > 0
GROUP BY
    ws.ws_web_site_sk,
    web.web_name,
    ship.sm_carrier,
    ware.w_state,
    promo.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
