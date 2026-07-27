WITH promo_match AS (
    SELECT p_promo_sk, p_promo_name
    FROM promotion
    WHERE regexp_like(p_promo_name, '(?i)discount')
),
city_match AS (
    SELECT ca_address_sk, ca_city
    FROM customer_address
    WHERE regexp_like(ca_city, '^A.*n$')
),
web_sales_filtered AS (
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_ship_mode_sk AS ship_mode_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN promo_match pm ON ws.ws_promo_sk = pm.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim dm ON ws.ws_sold_date_sk = dm.d_date_sk
    JOIN city_match ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE dm.d_year = 2000
      AND sm.sm_type LIKE 'AIR%'
),
store_sales_filtered AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_promo_sk AS promo_sk,
        NULL AS ship_mode_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN promo_match pm ON ss.ss_promo_sk = pm.p_promo_sk
    JOIN date_dim dm ON ss.ss_sold_date_sk = dm.d_date_sk
    JOIN city_match ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE dm.d_year = 2000
),
combined_sales AS (
    SELECT * FROM web_sales_filtered
    UNION ALL
    SELECT * FROM store_sales_filtered
)
SELECT
    dm.d_year,
    pm.p_promo_name,
    COALESCE(sm.sm_type, 'N/A') AS ship_type,
    CONCAT(pm.p_promo_name, '_', COALESCE(sm.sm_type, 'N/A')) AS promo_ship_combo,
    SUM(cs.net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.item_sk) AS distinct_items_sold
FROM combined_sales cs
JOIN promo_match pm ON cs.promo_sk = pm.p_promo_sk
LEFT JOIN ship_mode sm ON cs.ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim dm ON cs.sold_date_sk = dm.d_date_sk
GROUP BY
    dm.d_year,
    pm.p_promo_name,
    COALESCE(sm.sm_type, 'N/A'),
    CONCAT(pm.p_promo_name, '_', COALESCE(sm.sm_type, 'N/A'))
ORDER BY total_net_profit DESC
LIMIT 100
