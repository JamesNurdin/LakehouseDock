WITH sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        dd.d_year,
        dd.d_moy,
        dd.d_weekend,
        sm.sm_type,
        sm.sm_code
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE dd.d_year BETWEEN 1999 AND 2002
)
SELECT
    sd.d_year,
    sd.d_moy,
    sd.sm_type,
    SUM(sd.ws_ext_sales_price) AS total_sales,
    SUM(sd.ws_net_profit) AS total_profit,
    'Weekend' AS shipping_day_type
FROM sales_data sd
WHERE sd.d_weekend = 'Y'
GROUP BY sd.d_year, sd.d_moy, sd.sm_type
UNION ALL
SELECT
    sd.d_year,
    sd.d_moy,
    sd.sm_type,
    SUM(sd.ws_ext_sales_price) AS total_sales,
    SUM(sd.ws_net_profit) AS total_profit,
    'Weekday' AS shipping_day_type
FROM sales_data sd
WHERE sd.d_weekend = 'N'
GROUP BY sd.d_year, sd.d_moy, sd.sm_type
ORDER BY d_year, d_moy, sm_type, shipping_day_type
LIMIT 100
