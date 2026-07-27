WITH agg AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        cd.cd_marital_status AS marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
    FROM customer_demographics cd
    JOIN store_returns sr
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cd.cd_marital_status IN ('M', 'S')
      AND cd.cd_dep_employed_count >= 1
      AND ws.ws_ext_list_price > 5000
      AND ws.ws_ship_date_sk BETWEEN 2451450 AND 2451500
      AND i.inv_quantity_on_hand < 100
      AND w.w_state = 'CA'
      AND sr.sr_return_amt > 100.00
    GROUP BY ROLLUP (w.w_warehouse_id, cd.cd_marital_status)
)
SELECT
    warehouse_id,
    marital_status,
    total_sales,
    total_returns,
    total_inventory,
    total_net_profit,
    orders_cnt,
    CASE
        WHEN total_sales = 0 THEN 0
        ELSE total_net_profit / total_sales
    END AS profit_margin,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY warehouse_id ORDER BY total_net_profit DESC) AS rn_within_warehouse
FROM agg
WHERE NOT (warehouse_id IS NULL AND marital_status IS NULL)
ORDER BY profit_rank
