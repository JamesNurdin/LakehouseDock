WITH aggregated AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_state AS s_state,
        s.s_city AS s_city,
        d_ret.d_year AS year,
        d_ret.d_moy AS month,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(date_diff('day', d_ret.d_date, d_ship.d_date)) AS avg_shipping_delay
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_ret.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2000
    GROUP BY
        s.s_store_id,
        s.s_state,
        s.s_city,
        d_ret.d_year,
        d_ret.d_moy
)
SELECT
    s_store_id,
    s_state,
    s_city,
    year,
    month,
    total_quantity_sold,
    total_sales_amount,
    total_net_profit,
    total_return_quantity,
    total_return_amount,
    (total_net_profit - total_return_amount) AS net_effect,
    avg_shipping_delay,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY (total_net_profit - total_return_amount) DESC) AS profit_rank
FROM aggregated
ORDER BY net_effect DESC
LIMIT 100
