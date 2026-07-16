WITH inventory_by_warehouse AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory
    WHERE inv_date_sk BETWEEN 2450900 AND 2451100
    GROUP BY inv_warehouse_sk
),
sales_by_warehouse_gender AS (
    SELECT
        cs.cs_warehouse_sk AS warehouse_sk,
        cd.cd_gender,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'monthly'
      AND cs.cs_sold_date_sk BETWEEN 2450996 AND 2451087
    GROUP BY cs.cs_warehouse_sk, cd.cd_gender
)
SELECT
    w.w_warehouse_name,
    w.w_state,
    sbg.cd_gender,
    sbg.net_profit,
    sbg.total_quantity,
    sbg.avg_discount,
    ibw.total_inventory_qty,
    sbg.net_profit / NULLIF(ibw.total_inventory_qty, 0) AS profit_per_inventory
FROM sales_by_warehouse_gender sbg
JOIN warehouse w
    ON sbg.warehouse_sk = w.w_warehouse_sk
JOIN inventory_by_warehouse ibw
    ON w.w_warehouse_sk = ibw.inv_warehouse_sk
ORDER BY sbg.net_profit DESC
LIMIT 100
