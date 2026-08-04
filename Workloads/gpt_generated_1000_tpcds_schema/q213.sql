WITH billed AS (
    SELECT DISTINCT
        c.c_customer_id,
        ws.ws_web_site_sk,
        ws.ws_net_paid
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_hour BETWEEN 9 AND 12
      AND hd.hd_income_band_sk = 12
      AND ws.ws_wholesale_cost > 30
),
shipped AS (
    SELECT DISTINCT
        c.c_customer_id,
        ws.ws_web_site_sk,
        ws.ws_net_paid
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_hour BETWEEN 13 AND 16
      AND hd.hd_vehicle_count >= 2
      AND ws.ws_ext_list_price < 10000
)
SELECT c_customer_id,
       ws_web_site_sk,
       ws_net_paid
FROM billed
INTERSECT
SELECT c_customer_id,
       ws_web_site_sk,
       ws_net_paid
FROM shipped
ORDER BY c_customer_id
LIMIT 100
