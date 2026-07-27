WITH
    store_rev AS (
        SELECT
            i.i_item_id        AS item_id,
            i.i_item_desc     AS item_desc,
            SUM(ss.ss_ext_sales_price) AS total_revenue,
            'store_sales'     AS source
        FROM tpcds.store_sales ss
        JOIN tpcds.item i
            ON ss.ss_item_sk = i.i_item_sk
        WHERE ss.ss_item_sk IN (107683, 250021, 206779)
          AND ss.ss_sold_time_sk BETWEEN 30000 AND 70000
        GROUP BY i.i_item_id, i.i_item_desc
    ),
    catalog_rev AS (
        SELECT
            i.i_item_id        AS item_id,
            i.i_item_desc     AS item_desc,
            SUM(cs.cs_ext_sales_price) AS total_revenue,
            'catalog_sales'   AS source
        FROM tpcds.catalog_sales cs
        JOIN tpcds.item i
            ON cs.cs_item_sk = i.i_item_sk
        WHERE cs.cs_item_sk IN (73588, 189560, 193426)
          AND cs.cs_warehouse_sk = 1
        GROUP BY i.i_item_id, i.i_item_desc
    )
SELECT
    item_id,
    item_desc,
    total_revenue,
    source
FROM store_rev
UNION ALL
SELECT
    item_id,
    item_desc,
    total_revenue,
    source
FROM catalog_rev
ORDER BY total_revenue DESC
LIMIT 100
