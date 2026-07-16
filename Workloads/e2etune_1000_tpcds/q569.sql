WITH sales_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY ws.ws_warehouse_sk, cd.cd_gender, cd.cd_marital_status
),
inventory_agg AS (
    SELECT
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
)
SELECT
    w.w_state AS warehouse_state,
    s.cd_gender,
    s.cd_marital_status,
    s.total_net_profit,
    s.total_quantity,
    s.avg_discount,
    s.order_cnt,
    i.total_on_hand AS inventory_on_hand,
    s.total_net_profit / NULLIF(i.total_on_hand, 0) AS profit_per_inventory,
    RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_agg s
JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory_agg i ON s.ws_warehouse_sk = i.inv_warehouse_sk
WHERE w.w_state IS NOT NULL
ORDER BY profit_rank
LIMIT 50
