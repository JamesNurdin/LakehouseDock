WITH
    active_promos_2020 AS (
        SELECT p.p_promo_sk
        FROM promotion p
        JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
        JOIN date_dim d_end   ON p.p_end_date_sk = d_end.d_date_sk
        WHERE d_start.d_year = 2020 OR d_end.d_year = 2020
    ),
    used_promos_2020 AS (
        SELECT DISTINCT ws.ws_promo_sk AS p_promo_sk
        FROM web_sales ws
        JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
        WHERE d_sold.d_year = 2020
    ),
    unused_promos_2020 AS (
        SELECT p_promo_sk FROM active_promos_2020
        EXCEPT
        SELECT p_promo_sk FROM used_promos_2020
    )
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    d_sold.d_year,
    ws.ws_net_profit,
    ws.ws_quantity,
    sm.sm_code,
    sm.sm_carrier,
    ws.ws_ext_list_price,
    p.p_promo_name,
    cp.cp_catalog_page_id,
    ws.ws_net_paid,
    CASE
        WHEN ws.ws_quantity > 100 THEN 'HIGH'
        ELSE 'LOW'
    END AS quantity_flag,
    RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site w
    ON ws.ws_web_site_sk = w.web_site_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
    AND cp.cp_end_date_sk = d_ship.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
    AND inv.inv_item_sk = ws.ws_item_sk
LEFT JOIN unused_promos_2020 up
    ON p.p_promo_sk = up.p_promo_sk
WHERE
    d_sold.d_year = 2020
    AND w.web_country = 'United States'
    AND sm.sm_code IN ('AIR', 'SEA')
    AND p.p_discount_active = 'Y'
    AND ws.ws_wholesale_cost > 100
    AND inv.inv_quantity_on_hand > 0
    AND cp.cp_department = 'Electronics'
    AND up.p_promo_sk IS NULL
ORDER BY profit_rank
LIMIT 100
