/*
Goal: Rank orders by net profit within each warehouse for customers who match specific demographic and purchase criteria, include total return amounts, compute the average net profit for the warehouse, classify profit levels, and return the top 100 orders.
*/
WITH returns_agg AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    GROUP BY wr.wr_order_number, wr.wr_item_sk
)
SELECT
    ws.ws_order_number,
    w.w_warehouse_id,
    w.w_warehouse_name,
    c.c_customer_id,
    cd.cd_gender,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COALESCE(r.total_return_amt, 0) AS total_return_amount,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = ws.ws_warehouse_sk
    ) AS avg_warehouse_net_profit,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_net_profit) DESC) AS warehouse_order_rank,
    RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_net_profit_rank,
    CASE
        WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High'
        WHEN SUM(ws.ws_net_profit) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM web_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN returns_agg r
    ON ws.ws_order_number = r.wr_order_number
   AND ws.ws_item_sk = r.wr_item_sk
WHERE
    c.c_birth_month IN (2, 4, 6, 7, 10)
    AND cd.cd_education_status = '4 yr Degree'
    AND cd.cd_purchase_estimate > 3000
    AND w.w_state = 'CA'
    AND ws.ws_net_paid_inc_ship_tax > 2000
    AND ws.ws_ship_cdemo_sk IN (293885, 816413)
GROUP BY
    ws.ws_order_number,
    w.w_warehouse_id,
    w.w_warehouse_name,
    c.c_customer_id,
    cd.cd_gender,
    ws.ws_warehouse_sk,
    r.total_return_amt
ORDER BY
    warehouse_order_rank,
    total_net_profit DESC
LIMIT 100
