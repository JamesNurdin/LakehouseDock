WITH item_warehouse_sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk
)
,
 billed_sales AS (
    SELECT
        i.i_item_id,
        w.w_warehouse_name,
        iws.total_net_paid,
        iws.sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY iws.total_net_paid DESC) AS warehouse_item_rank
    FROM item_warehouse_sales iws
    JOIN item i ON iws.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON iws.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate >= 5000
    GROUP BY i.i_item_id, w.w_warehouse_name, iws.total_net_paid, iws.sales_cnt, w.w_warehouse_name
)
,
 shipped_sales AS (
    SELECT
        i.i_item_id,
        w.w_warehouse_name,
        iws.total_net_paid,
        iws.sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY iws.total_net_paid DESC) AS warehouse_item_rank
    FROM item_warehouse_sales iws
    JOIN item i ON iws.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON iws.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_purchase_estimate < 8000
      AND sm.sm_type = 'AIR'
    GROUP BY i.i_item_id, w.w_warehouse_name, iws.total_net_paid, iws.sales_cnt, w.w_warehouse_name
)
SELECT *
FROM billed_sales
UNION ALL
SELECT *
FROM shipped_sales
ORDER BY warehouse_item_rank ASC, total_net_paid DESC
LIMIT 100
