WITH ws AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        i.i_item_id,
        ws.ws_order_number AS order_number,
        ws.ws_net_profit AS net_profit,
        ws.ws_ship_mode_sk AS ship_mode_sk,
        ARRAY[ws.ws_sales_price, ws.ws_ext_sales_price] AS price_metrics
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
),
cs AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        i.i_item_id,
        cs.cs_order_number AS order_number,
        cs.cs_net_profit AS net_profit,
        cs.cs_ship_mode_sk AS ship_mode_sk,
        ARRAY[cs.cs_sales_price, cs.cs_ext_sales_price] AS price_metrics
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
),
union_sales AS (
    SELECT item_sk, i_item_id, order_number, net_profit, ship_mode_sk, price_metrics
    FROM ws
    UNION
    SELECT item_sk, i_item_id, order_number, net_profit, ship_mode_sk, price_metrics
    FROM cs
),
returned_items AS (
    SELECT cr.cr_item_sk AS item_sk
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    UNION
    SELECT wr.wr_item_sk AS item_sk
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
),
final_set AS (
    SELECT *
    FROM union_sales
    EXCEPT
    SELECT us.*
    FROM union_sales us
    JOIN returned_items ri ON us.item_sk = ri.item_sk
)
SELECT
    f.item_sk,
    f.i_item_id,
    f.net_profit,
    sm.sm_type AS ship_mode_type,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = f.item_sk) AS store_return_cnt,
    price_val
FROM final_set f
JOIN ship_mode sm ON f.ship_mode_sk = sm.sm_ship_mode_sk
CROSS JOIN UNNEST(f.price_metrics) AS t(price_val)
ORDER BY f.net_profit DESC
LIMIT 100
