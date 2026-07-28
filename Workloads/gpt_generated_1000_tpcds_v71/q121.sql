WITH avg_price_cte AS (
    SELECT avg(i_current_price) AS avg_price
    FROM item
)
SELECT * FROM (
    SELECT
        'STORE' AS channel,
        s.s_store_id AS location_id,
        s.s_store_name AS location_name,
        t.t_hour AS hour,
        i.i_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS net_profit,
        CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        CASE WHEN i.i_current_price > (SELECT avg_price FROM avg_price_cte) THEN 'Above' ELSE 'Below' END AS price_vs_avg,
        row_number() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_profit DESC) AS rank
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND s.s_zip = '79532'
) AS store_part
UNION ALL
SELECT * FROM (
    SELECT
        'WEB' AS channel,
        c.c_customer_id AS location_id,
        c.c_first_name || ' ' || c.c_last_name AS location_name,
        t.t_hour AS hour,
        i.i_item_id AS item_id,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_profit,
        CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        CASE WHEN i.i_current_price > (SELECT avg_price FROM avg_price_cte) THEN 'Above' ELSE 'Below' END AS price_vs_avg,
        row_number() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE t.t_hour BETWEEN 13 AND 17
      AND sm.sm_type = 'AIR'
) AS web_part
ORDER BY channel, net_profit DESC
LIMIT 100
