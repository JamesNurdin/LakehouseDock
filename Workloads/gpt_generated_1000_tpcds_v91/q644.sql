WITH ws_agg AS (
    SELECT
        ws_ship_mode_sk,
        ws_sold_time_sk,
        ws_web_page_sk,
        SUM(ws_ext_sales_price) AS sum_ws_ext_sales_price,
        AVG(ws_net_paid) AS avg_ws_net_paid,
        COUNT(*) AS cnt_ws
    FROM web_sales
    WHERE ws_ext_list_price > 5000.00
      AND ws_wholesale_cost < 50.00
      AND ws_ship_cdemo_sk IN (1632520, 1895897)
    GROUP BY ws_ship_mode_sk, ws_sold_time_sk, ws_web_page_sk
),
cs_agg AS (
    SELECT
        cs_ship_mode_sk,
        cs_sold_time_sk,
        SUM(cs_ext_sales_price) AS sum_cs_ext_sales_price,
        AVG(cs_net_paid) AS avg_cs_net_paid,
        COUNT(*) AS cnt_cs
    FROM catalog_sales
    WHERE cs_quantity > 5
      AND cs_net_profit > 1000.00
    GROUP BY cs_ship_mode_sk, cs_sold_time_sk
),
union_data AS (
    -- First branch – AIR and GROUND shipping modes
    SELECT
        sm.sm_ship_mode_id            AS ship_mode_id,
        td.t_hour                     AS hour_of_day,
        wp.wp_type                    AS page_type,
        SUM(wa.sum_ws_ext_sales_price) AS total_ws_ext_sales,
        SUM(ca.sum_cs_ext_sales_price) AS total_cs_ext_sales,
        COUNT(*)                      AS num_rows,
        CASE WHEN sm.sm_carrier = 'UPS' THEN SUM(wa.sum_ws_ext_sales_price) ELSE 0 END AS ups_total_ws_sales,
        (SELECT AVG(ws_sub.ws_ext_sales_price)
         FROM web_sales ws_sub
         WHERE ws_sub.ws_wholesale_cost < 50.00
           AND ws_sub.ws_ext_list_price > 5000.00) AS overall_avg_ws_price
    FROM cs_agg ca
    JOIN ship_mode sm ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON ca.cs_sold_time_sk = td.t_time_sk
    JOIN ws_agg wa ON wa.ws_ship_mode_sk = sm.sm_ship_mode_sk
                  AND wa.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp ON wa.ws_web_page_sk = wp.wp_web_page_sk
    WHERE sm.sm_type IN ('AIR', 'GROUND')
      AND td.t_time IN (9, 16)
      AND td.t_second BETWEEN 10 AND 20
      AND wp.wp_char_count > 2000
      AND wp.wp_creation_date_sk = 2450809
      AND wp.wp_web_page_id LIKE 'AAAAAAAA%'
    GROUP BY sm.sm_ship_mode_id, td.t_hour, wp.wp_type, sm.sm_carrier

    UNION

    -- Second branch – SEA and RAIL shipping modes
    SELECT
        sm.sm_ship_mode_id            AS ship_mode_id,
        td.t_hour                     AS hour_of_day,
        wp.wp_type                    AS page_type,
        SUM(wa.sum_ws_ext_sales_price) AS total_ws_ext_sales,
        SUM(ca.sum_cs_ext_sales_price) AS total_cs_ext_sales,
        COUNT(*)                      AS num_rows,
        CASE WHEN sm.sm_carrier = 'FEDEx' THEN SUM(wa.sum_ws_ext_sales_price) ELSE 0 END AS ups_total_ws_sales,
        (SELECT AVG(ws_sub.ws_ext_sales_price)
         FROM web_sales ws_sub
         WHERE ws_sub.ws_wholesale_cost < 50.00
           AND ws_sub.ws_ext_list_price > 5000.00) AS overall_avg_ws_price
    FROM cs_agg ca
    JOIN ship_mode sm ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON ca.cs_sold_time_sk = td.t_time_sk
    JOIN ws_agg wa ON wa.ws_ship_mode_sk = sm.sm_ship_mode_sk
                  AND wa.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp ON wa.ws_web_page_sk = wp.wp_web_page_sk
    WHERE sm.sm_type IN ('SEA', 'RAIL')
      AND td.t_time IN (2, 6)
      AND td.t_second BETWEEN 12 AND 18
      AND wp.wp_char_count BETWEEN 1000 AND 3000
      AND wp.wp_creation_date_sk = 2450811
      AND wp.wp_type = 'CONTENT'
    GROUP BY sm.sm_ship_mode_id, td.t_hour, wp.wp_type, sm.sm_carrier
)
SELECT
    ship_mode_id,
    hour_of_day,
    page_type,
    total_ws_ext_sales,
    total_cs_ext_sales,
    num_rows,
    ups_total_ws_sales,
    overall_avg_ws_price,
    ROW_NUMBER() OVER (PARTITION BY ship_mode_id ORDER BY total_ws_ext_sales DESC) AS sales_rank
FROM union_data
ORDER BY total_ws_ext_sales DESC
LIMIT 100
