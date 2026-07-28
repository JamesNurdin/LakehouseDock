WITH cs AS (
    SELECT cs_order_number,
           cs_sold_date_sk,
           cs_ship_date_sk,
           cs_catalog_page_sk,
           cs_ship_mode_sk,
           cs_promo_sk,
           cs_quantity,
           cs_net_profit
    FROM catalog_sales
    WHERE cs_quantity BETWEEN 1 AND 10
),
ws AS (
    SELECT ws_order_number,
           ws_sold_date_sk,
           ws_ship_date_sk,
           ws_web_site_sk,
           ws_ship_mode_sk,
           ws_promo_sk,
           ws_quantity,
           ws_net_profit
    FROM web_sales
    WHERE ws_quantity > 5
)
SELECT
    d_sold.d_year,
    sm.sm_type,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    SUM(cs.cs_net_profit) AS catalog_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(ws.ws_net_profit) AS web_profit,
    (SELECT MAX(p_inner.p_cost) FROM promotion p_inner) AS max_promo_cost
FROM cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
-- join web‑sales side
JOIN ws
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND ws.ws_promo_sk = p.p_promo_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
WHERE
    d_sold.d_year = 2001
    AND d_sold.d_date >= DATE '2000-01-01'
    AND cp.cp_department = 'Books'
    AND sm.sm_type = 'AIR'
    AND p.p_discount_active = 'Y'
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_cost > 5000
    )
GROUP BY ROLLUP (d_sold.d_year, sm.sm_type)
ORDER BY d_sold.d_year ASC, sm.sm_type ASC
LIMIT 100
