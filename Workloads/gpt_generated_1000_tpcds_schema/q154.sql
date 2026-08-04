WITH intersect_orders AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_ext_tax > 100
    INTERSECT
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_quantity > 5
)
SELECT
    ws.ws_order_number,
    hd_bill.hd_buy_potential,
    i.i_brand,
    t_sales.t_hour,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amt,
    RANK() OVER (PARTITION BY hd_bill.hd_buy_potential ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
    CASE
        WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status
FROM web_sales ws
JOIN time_dim t_sales
    ON ws.ws_sold_time_sk = t_sales.t_time_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
JOIN intersect_orders io
    ON ws.ws_order_number = io.ws_order_number
WHERE
    i.i_formulation LIKE '%steel%'
    AND i.i_units = 'Case'
    AND hd_bill.hd_buy_potential = '>10000'
    AND t_sales.t_hour BETWEEN 7 AND 18
GROUP BY
    ws.ws_order_number,
    hd_bill.hd_buy_potential,
    i.i_brand,
    t_sales.t_hour
ORDER BY total_profit DESC
LIMIT 100
