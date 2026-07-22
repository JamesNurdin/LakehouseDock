WITH cs_joined AS (
    SELECT
        cs.cs_item_sk,
        i_cs.i_category,
        t_cs.t_hour AS cs_hour,
        hd_bill_cs.hd_buy_potential,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN item i_cs
        ON cs.cs_item_sk = i_cs.i_item_sk
    JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN household_demographics hd_bill_cs
        ON cs.cs_bill_hdemo_sk = hd_bill_cs.hd_demo_sk
    JOIN household_demographics hd_ship_cs
        ON cs.cs_ship_hdemo_sk = hd_ship_cs.hd_demo_sk
    WHERE i_cs.i_current_price > 5
),
ws_joined AS (
    SELECT
        ws.ws_item_sk,
        i_ws.i_category,
        t_ws.t_hour AS ws_hour,
        hd_bill_ws.hd_buy_potential,
        ws.ws_net_profit,
        ws.ws_order_number
    FROM web_sales ws
    JOIN item i_ws
        ON ws.ws_item_sk = i_ws.i_item_sk
    JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN household_demographics hd_bill_ws
        ON ws.ws_bill_hdemo_sk = hd_bill_ws.hd_demo_sk
    JOIN household_demographics hd_ship_ws
        ON ws.ws_ship_hdemo_sk = hd_ship_ws.hd_demo_sk
    WHERE i_ws.i_current_price > 5
)
SELECT
    cs.i_category,
    cs.cs_hour,
    cs.hd_buy_potential,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    AVG(ws.ws_hour) AS avg_web_hour
FROM cs_joined cs
JOIN ws_joined ws
    ON cs.cs_item_sk = ws.ws_item_sk
GROUP BY
    cs.i_category,
    cs.cs_hour,
    cs.hd_buy_potential
ORDER BY total_catalog_profit DESC
LIMIT 100
