WITH joined_data AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_warehouse_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        cp.cp_catalog_page_number,
        c.c_customer_id,
        c.c_birth_year,
        ca.ca_state,
        cd.cd_gender,
        w.w_warehouse_name,
        w.w_state,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON w.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN web_sales ws
        ON w.w_warehouse_sk = ws.ws_warehouse_sk
        AND c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cp.cp_catalog_page_number IN (10, 18, 21)
      AND c.c_birth_year BETWEEN 1930 AND 1975
      AND ca.ca_state = 'CA'
      AND cs.cs_quantity > 10
      AND ws.ws_quantity > 5
      AND inv.inv_quantity_on_hand > 0
),
aggregated AS (
    SELECT
        jd.cs_bill_customer_sk AS customer_sk,
        jd.cs_warehouse_sk AS warehouse_sk,
        COUNT(DISTINCT jd.cs_order_number) AS catalog_orders,
        SUM(jd.cs_net_profit) AS catalog_profit,
        SUM(jd.cs_quantity) AS catalog_qty,
        COUNT(DISTINCT jd.ws_order_number) AS web_orders,
        SUM(jd.ws_net_profit) AS web_profit,
        SUM(jd.ws_quantity) AS web_qty,
        MAX(jd.inv_quantity_on_hand) AS inventory_on_hand,
        MIN(jd.w_warehouse_name) AS warehouse_name
    FROM joined_data jd
    GROUP BY jd.cs_bill_customer_sk, jd.cs_warehouse_sk
)
SELECT
    c.c_customer_id,
    agg.warehouse_name,
    (agg.catalog_profit + agg.web_profit) AS total_net_profit,
    (agg.catalog_qty + agg.web_qty) AS total_quantity,
    agg.inventory_on_hand
FROM aggregated agg
JOIN customer c
    ON agg.customer_sk = c.c_customer_sk
WHERE (agg.catalog_profit + agg.web_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
