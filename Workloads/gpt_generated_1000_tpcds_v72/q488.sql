/*
Goal: Identify high‑value catalog orders together with related web and store sales, enriched with customer and warehouse details, applying multiple filters, a CASE‑based discount flag, a scalar subquery for average warehouse profit, and a window rank of profit within each warehouse. The result is ordered by the profit rank and limited to the top 100 rows.
*/
WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_quantity,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_coupon_amt,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        w.w_warehouse_name,
        w.w_state,
        w.w_warehouse_sk,
        CASE WHEN cs.cs_ext_discount_amt > 200 THEN 'High' ELSE 'Low' END AS discount_level,
        (
            SELECT AVG(cs2.cs_net_profit)
            FROM catalog_sales cs2
            WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
        ) AS avg_warehouse_profit,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY cs.cs_net_profit DESC) AS profit_rank
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
       AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
       AND ws.ws_bill_addr_sk = ca.ca_address_sk
       AND ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_quantity > 10
      AND cs.cs_ext_discount_amt BETWEEN 50 AND 500
      AND ws.ws_quantity > 5
      AND ss.ss_coupon_amt > 0
      AND ca.ca_state = 'CA'
      AND w.w_state = 'TX'
      AND cd.cd_gender = 'M'
)
SELECT
    cs_order_number,
    cs_net_paid,
    cs_net_profit,
    ws_net_paid,
    ss_net_paid,
    cd_gender,
    ca_city,
    w_warehouse_name,
    discount_level,
    avg_warehouse_profit,
    profit_rank
FROM base
ORDER BY profit_rank, cs_order_number
LIMIT 100
