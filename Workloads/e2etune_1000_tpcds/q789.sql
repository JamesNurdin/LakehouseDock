WITH store_agg AS (
    SELECT
        t.t_hour AS hour,
        i.i_brand AS brand,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_ext_discount_amt) AS store_discount
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 2
      AND hd.hd_income_band_sk >= 3
      AND i.i_size IN ('large', 'extra large')
      AND t.t_hour BETWEEN 10 AND 20
    GROUP BY t.t_hour, i.i_brand
),
web_agg AS (
    SELECT
        t.t_hour AS hour,
        i.i_brand AS brand,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_ext_discount_amt) AS web_discount
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE hd.hd_vehicle_count >= 2
      AND hd.hd_income_band_sk >= 3
      AND i.i_size IN ('large', 'extra large')
      AND t.t_hour BETWEEN 10 AND 20
      AND w.web_country = 'United States'
    GROUP BY t.t_hour, i.i_brand
)
SELECT
    COALESCE(s.hour, w.hour) AS hour,
    COALESCE(s.brand, w.brand) AS brand,
    COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit,
    COALESCE(s.store_sales, 0) + COALESCE(w.web_sales, 0) AS total_sales,
    (COALESCE(s.store_discount, 0) + COALESCE(w.web_discount, 0)) /
        NULLIF(COALESCE(s.store_sales, 0) + COALESCE(w.web_sales, 0), 0) AS discount_rate
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.hour = w.hour AND s.brand = w.brand
ORDER BY total_net_profit DESC
LIMIT 50
