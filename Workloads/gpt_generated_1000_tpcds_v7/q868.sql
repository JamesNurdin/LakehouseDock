WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_warehouse_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_quantity
    FROM tpcds.web_sales ws
    WHERE ws.ws_sales_price > 50
      AND ws.ws_net_profit > 0
      AND ws.ws_quantity >= 1
)
SELECT
    ws.ws_order_number,
    ws.ws_sales_price,
    ws.ws_net_profit,
    w.w_warehouse_name,
    cd.cd_gender,
    cd.cd_marital_status,
    RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY ws.ws_sales_price DESC) AS price_rank
FROM filtered_sales ws
JOIN tpcds.warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'M'
  AND cd.cd_marital_status = 'M'
  AND cd.cd_dep_count >= 2
  AND w.w_warehouse_sq_ft > 500000
ORDER BY price_rank, ws.ws_order_number
LIMIT 100
