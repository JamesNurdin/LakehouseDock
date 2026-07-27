WITH inv_agg AS (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_date_sk
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    sm.sm_type,
    sm.sm_carrier,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_quantity) AS total_quantity,
    inv_agg.total_inventory,
    ROW_NUMBER() OVER (PARTITION BY sm.sm_type ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rn
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN inv_agg
    ON ws.ws_sold_date_sk = inv_agg.inv_date_sk
WHERE
    sm.sm_type IN ('EXPRESS', 'REGULAR')
    AND sm.sm_carrier = 'TBS'
    AND d_sold.d_current_quarter = 'Y'
    AND d_ship.d_current_week = 'N'
    AND ws.ws_promo_sk = 871
    AND d_sold.d_current_day = 'N'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    sm.sm_type,
    sm.sm_carrier,
    inv_agg.total_inventory
HAVING
    SUM(ws.ws_ext_sales_price) > 10000
ORDER BY
    total_sales DESC,
    rn
LIMIT 100
