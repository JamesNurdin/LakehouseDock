WITH
    sales_sample AS (
        SELECT * FROM web_sales TABLESAMPLE BERNOULLI (10)
    ),
    sales_orders AS (
        SELECT ws_order_number FROM web_sales
    ),
    returns_orders AS (
        SELECT wr_order_number FROM web_returns
    ),
    non_returned_orders AS (
        SELECT ws_order_number FROM sales_orders
        EXCEPT
        SELECT wr_order_number FROM returns_orders
    ),
    scalar_max_qty AS (
        SELECT MAX(ws_quantity) AS max_qty FROM web_sales WHERE ws_quantity < 1000
    )
SELECT *
FROM (
    SELECT
        ws.ws_order_number AS order_number,
        COUNT(*) AS cnt,
        SUM(ws.ws_net_profit) AS amount,
        AVG(ws.ws_quantity) AS avg_qty
    FROM
        sales_sample ws
        FULL OUTER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN time_dim td_sold ON ws.ws_sold_time_sk = td_sold.t_time_sk
        LEFT JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
        LEFT JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
        LEFT JOIN time_dim td_extra ON ws.ws_sold_time_sk = td_extra.t_time_sk
        LEFT JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
        LEFT JOIN time_dim td_ret ON wr.wr_returned_time_sk = td_ret.t_time_sk
        RIGHT OUTER JOIN time_dim td_right ON ws.ws_sold_time_sk = td_right.t_time_sk
        INNER JOIN non_returned_orders nro ON ws.ws_order_number = nro.ws_order_number
    WHERE
        ws.ws_quantity > (SELECT max_qty FROM scalar_max_qty)
        AND p.p_channel_dmail = 'Y'
    GROUP BY
        GROUPING SETS (
            (ws.ws_order_number),
            ()
        )
    HAVING COUNT(*) > 0
) 
UNION DISTINCT
SELECT *
FROM (
    SELECT
        wr.wr_order_number AS order_number,
        COUNT(*) AS cnt,
        SUM(wr.wr_return_amt) AS amount,
        AVG(wr.wr_return_quantity) AS avg_qty
    FROM
        web_returns wr
        LEFT JOIN web_sales ws ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
        LEFT JOIN time_dim td_ret ON wr.wr_returned_time_sk = td_ret.t_time_sk
        LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        LEFT JOIN time_dim td_sold ON ws.ws_sold_time_sk = td_sold.t_time_sk
    WHERE
        wr.wr_fee > (SELECT MIN(wr_fee) FROM web_returns)
    GROUP BY
        GROUPING SETS (
            (wr.wr_order_number),
            ()
        )
) 
LIMIT 100
