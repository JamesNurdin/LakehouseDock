WITH catalog AS (
    SELECT
        'Catalog' AS sales_source,
        i.i_item_id,
        i.i_category,
        cs.cs_net_paid_inc_tax AS net_paid,
        cs.cs_net_profit AS net_profit
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_net_paid_inc_tax > 1000
      AND cc.cc_country = 'United States'
      AND cc.cc_suite_number IN ('Suite 440 ','Suite 340 ')
),
store AS (
    SELECT
        'Store' AS sales_source,
        i.i_item_id,
        i.i_category,
        ss.ss_net_paid_inc_tax AS net_paid,
        ss.ss_net_profit AS net_profit
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_paid_inc_tax > 1000
      AND i.i_category = 'Sports'
),
combined AS (
    SELECT * FROM catalog
    UNION ALL
    SELECT * FROM store
)
SELECT
    combined.sales_source,
    combined.i_item_id,
    combined.i_category,
    SUM(combined.net_paid)   AS total_net_paid,
    SUM(combined.net_profit) AS total_net_profit
FROM combined
GROUP BY GROUPING SETS (
    (combined.sales_source, combined.i_item_id, combined.i_category),
    (combined.sales_source, combined.i_item_id),
    (combined.sales_source),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
