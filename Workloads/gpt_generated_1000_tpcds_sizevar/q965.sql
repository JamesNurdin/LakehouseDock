WITH intersect_orders AS (
    SELECT ws_order_number AS order_num
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20000101 AND 20000131
    INTERSECT
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 20000101 AND 20000131
)
SELECT
    hd_bill.hd_demo_sk,
    td.t_shift,
    wp.wp_type,
    SUM(ws.ws_ext_sales_price)               AS total_sales,
    SUM(lt.line_total)                        AS total_line_value,
    COUNT(DISTINCT ws.ws_item_sk)             AS distinct_items,
    AVG(ws.ws_net_profit)                     AS avg_group_profit,
    (SELECT avg(ws_net_profit) FROM web_sales WHERE ws_sold_date_sk = 20000101) AS overall_avg_profit
FROM web_sales ws
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN time_dim td2
    ON wr.wr_returned_time_sk = td2.t_time_sk
LEFT JOIN web_page wp2
    ON wr.wr_web_page_sk = wp2.wp_web_page_sk
FULL OUTER JOIN intersect_orders io
    ON ws.ws_order_number = io.order_num
CROSS JOIN LATERAL (
    SELECT ws.ws_quantity * ws.ws_sales_price AS line_total
) lt
WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_quantity > 0
    )
  AND ws.ws_net_profit > (SELECT avg(ws_net_profit) FROM web_sales WHERE ws_sold_date_sk = 20000101)
GROUP BY GROUPING SETS (
    (hd_bill.hd_demo_sk, td.t_shift, wp.wp_type),
    (hd_bill.hd_demo_sk, td.t_shift),
    (wp.wp_type),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
