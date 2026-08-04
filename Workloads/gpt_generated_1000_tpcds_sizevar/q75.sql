WITH avg_profit AS (
    SELECT avg(ws_net_profit) AS avg_profit
    FROM web_sales
),
sub_a AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        CASE WHEN ws.ws_quantity > 10 THEN 'Large' ELSE 'Small' END AS order_size_category,
        w.w_state
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'MI'
      AND ws.ws_net_profit > (SELECT avg_profit FROM avg_profit)
),
sub_b AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        CASE WHEN ws.ws_quantity > 10 THEN 'Large' ELSE 'Small' END AS order_size_category,
        w.w_state
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'MI'
      AND ws.ws_net_profit > (SELECT avg_profit FROM avg_profit)
)
SELECT
    diff.ws_order_number,
    diff.ws_net_profit,
    diff.order_size_category,
    diff.w_state
FROM (
    SELECT * FROM sub_a
    EXCEPT
    SELECT * FROM sub_b
) AS diff
ORDER BY diff.ws_order_number
