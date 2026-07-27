WITH store_sales_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_paid) AS total_paid,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND ss.ss_net_paid > 0
    GROUP BY ss.ss_item_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_paid) AS total_paid,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cp.cp_type = 'Discount'
      AND cd.cd_gender = 'M'
    GROUP BY cs.cs_item_sk
)
SELECT
    agg.item_sk,
    SUM(agg.total_paid) AS total_paid,
    SUM(agg.total_profit) AS total_profit
FROM (
    SELECT item_sk, total_paid, total_profit FROM store_sales_agg
    UNION ALL
    SELECT item_sk, total_paid, total_profit FROM catalog_sales_agg
) agg
GROUP BY agg.item_sk
ORDER BY total_paid DESC
LIMIT 100
