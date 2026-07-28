WITH cs_base AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        i.i_item_id,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        w.w_city,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_bill_cdemo_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cp.cp_catalog_number IN (8, 12, 16)
      AND cd.cd_purchase_estimate > 5000
      AND w.w_city = 'Seattle'
),
web_sales_with_returns AS (
    SELECT ws.ws_item_sk, ws.ws_bill_cdemo_sk, ws.ws_order_number
    FROM tpcds.web_sales ws
    JOIN tpcds.web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
)
SELECT
    cp_catalog_page_id,
    i_item_id,
    SUM(cs_net_profit) AS total_profit,
    CASE WHEN cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_group,
    RANK() OVER (PARTITION BY cp_catalog_number ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
FROM cs_base
WHERE NOT EXISTS (
        SELECT 1
        FROM tpcds.store_sales ss
        WHERE ss.ss_item_sk = cs_base.cs_item_sk
          AND ss.ss_cdemo_sk = cs_base.cs_bill_cdemo_sk
    )
  AND NOT EXISTS (
        SELECT 1
        FROM web_sales_with_returns wswr
        WHERE wswr.ws_item_sk = cs_base.cs_item_sk
          AND wswr.ws_bill_cdemo_sk = cs_base.cs_bill_cdemo_sk
    )
GROUP BY cp_catalog_page_id, i_item_id, cd_gender, cp_catalog_number
ORDER BY profit_rank, total_profit DESC
LIMIT 100
