WITH item_sales AS (
    SELECT
        cs.cs_warehouse_sk,
        w.w_warehouse_name,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_profit) AS daily_net_profit,
        SUM(cs.cs_quantity) AS daily_quantity,
        MAX(c.c_preferred_cust_flag) AS preferred_cust_flag
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY cs.cs_warehouse_sk, w.w_warehouse_name, cs.cs_item_sk, cs.cs_sold_date_sk
)
SELECT
    ws.w_warehouse_name,
    ws.cs_item_sk,
    ws.cs_sold_date_sk,
    ws.daily_net_profit,
    ws.daily_quantity,
    ws.preferred_cust_flag,
    CASE
        WHEN ws.daily_quantity > 100 THEN 'HIGH_VOLUME'
        WHEN ws.daily_quantity BETWEEN 50 AND 100 THEN 'MEDIUM_VOLUME'
        ELSE 'LOW_VOLUME'
    END AS volume_category,
    AVG(ws.daily_net_profit) OVER (
        PARTITION BY ws.cs_warehouse_sk, ws.cs_item_sk
        ORDER BY ws.cs_sold_date_sk
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3_days_profit,
    ROW_NUMBER() OVER (PARTITION BY ws.cs_warehouse_sk ORDER BY ws.daily_net_profit DESC) AS profit_rank_within_wh
FROM item_sales ws
ORDER BY ws.w_warehouse_name, profit_rank_within_wh
LIMIT 200
