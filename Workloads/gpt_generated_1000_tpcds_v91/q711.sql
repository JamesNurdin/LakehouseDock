WITH item_word_counts AS (
    SELECT i.i_item_sk,
           COUNT(DISTINCT word) AS distinct_word_count
    FROM tpcds.item i
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
    GROUP BY i.i_item_sk
),

sales_agg AS (
    SELECT cp.cp_department AS group_name,
           sm.sm_type AS ship_type,
           CAST(SUM(cs.cs_net_paid) AS decimal(15,2)) AS total_sales,
           CAST(SUM(cs.cs_net_profit) AS decimal(15,2)) AS total_profit,
           CASE WHEN SUM(cs.cs_net_paid) > 50000 THEN 'High' ELSE 'Low' END AS sales_category,
           SUM(iwc.distinct_word_count) AS total_word_count
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN item_word_counts iwc ON i.i_item_sk = iwc.i_item_sk
    GROUP BY ROLLUP (cp.cp_department, sm.sm_type)
    HAVING SUM(cs.cs_net_paid) > 10000
),

inventory_word_counts AS (
    SELECT i.i_item_sk,
           COUNT(DISTINCT word) AS distinct_word_count
    FROM tpcds.item i
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
    GROUP BY i.i_item_sk
),

inventory_agg AS (
    SELECT w.w_warehouse_name AS group_name,
           CAST(NULL AS varchar) AS ship_type,
           CAST(SUM(COALESCE(inv.inv_quantity_on_hand, 0) * COALESCE(i.i_current_price, 0)) AS decimal(15,2)) AS total_sales,
           CAST(NULL AS decimal(15,2)) AS total_profit,
           CASE WHEN SUM(COALESCE(inv.inv_quantity_on_hand, 0) * COALESCE(i.i_current_price, 0)) > 200000 THEN 'High' ELSE 'Low' END AS sales_category,
           COALESCE(SUM(iwc.distinct_word_count), 0) AS total_word_count
    FROM tpcds.warehouse w
    FULL OUTER JOIN tpcds.inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.item i ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN inventory_word_counts iwc ON i.i_item_sk = iwc.i_item_sk
    GROUP BY ROLLUP (w.w_warehouse_name)
    HAVING SUM(COALESCE(inv.inv_quantity_on_hand, 0) * COALESCE(i.i_current_price, 0)) > 50000
)

SELECT group_name,
       ship_type,
       total_sales,
       total_profit,
       sales_category,
       total_word_count
FROM sales_agg
UNION ALL
SELECT group_name,
       ship_type,
       total_sales,
       total_profit,
       sales_category,
       total_word_count
FROM inventory_agg
ORDER BY total_sales DESC
LIMIT 100
