WITH store_sales_agg AS (
    SELECT
        d.d_date AS sales_date,
        'STORE' AS sales_channel,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        (SELECT AVG(cs2.cs_net_profit)
         FROM catalog_sales cs2
         WHERE cs2.cs_item_sk = ss.ss_item_sk) AS avg_other_channel_item_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY d.d_date, ss.ss_item_sk
),
catalog_sales_agg AS (
    SELECT
        d.d_date AS sales_date,
        'CATALOG' AS sales_channel,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        (SELECT AVG(ss2.ss_net_profit)
         FROM store_sales ss2
         WHERE ss2.ss_item_sk = cs.cs_item_sk) AS avg_other_channel_item_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY d.d_date, cs.cs_item_sk
)
SELECT DISTINCT
    combined.sales_date,
    combined.sales_channel,
    combined.item_sk,
    combined.total_net_paid,
    combined.total_net_profit,
    combined.profit_category,
    combined.avg_other_channel_item_profit
FROM (
    SELECT
        sales_date,
        sales_channel,
        item_sk,
        total_net_paid,
        total_net_profit,
        profit_category,
        avg_other_channel_item_profit
    FROM store_sales_agg
    UNION ALL
    SELECT
        sales_date,
        sales_channel,
        item_sk,
        total_net_paid,
        total_net_profit,
        profit_category,
        avg_other_channel_item_profit
    FROM catalog_sales_agg
) combined
WHERE combined.profit_category = 'High'
ORDER BY combined.sales_date DESC, combined.total_net_paid DESC
LIMIT 100
