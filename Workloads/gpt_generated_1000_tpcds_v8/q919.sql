WITH sales_by_page AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_description,
        COUNT(cs.cs_order_number) AS num_orders,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    RIGHT OUTER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE
        cp.cp_description IS NOT NULL
        AND REGEXP_LIKE(cp.cp_description, '(?i)electronic')
        AND cp.cp_description LIKE '%2022%'
    GROUP BY cp.cp_catalog_page_sk, cp.cp_department, cp.cp_description
),

inventory_agg AS (
    SELECT
        w.w_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS warehouse_qty
    FROM warehouse w
    CROSS JOIN LATERAL (
        SELECT inv_quantity_on_hand
        FROM inventory inv TABLESAMPLE BERNOULLI (10)
        WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
    ) inv
    GROUP BY w.w_warehouse_sk
),

item_excluded AS (
    SELECT cs.cs_item_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE REGEXP_LIKE(cp.cp_description, 'Laptop')
    EXCEPT
    SELECT sr.sr_item_sk FROM store_returns sr
),

final AS (
    SELECT
        sbp.cp_catalog_page_sk,
        sbp.cp_department,
        REGEXP_EXTRACT(sbp.cp_description, '(\\w+)') AS first_word_desc,
        sbp.num_orders,
        sbp.total_sales,
        ia.warehouse_qty,
        CASE
            WHEN sbp.total_sales > 5000 THEN CONCAT('High-', sbp.cp_department)
            ELSE CONCAT('Low-', sbp.cp_department)
        END AS sales_category
    FROM sales_by_page sbp
    LEFT JOIN inventory_agg ia
        ON ia.w_warehouse_sk = (
            SELECT w_warehouse_sk FROM warehouse LIMIT 1
        )
    WHERE sbp.cp_catalog_page_sk IN (SELECT cs_item_sk FROM item_excluded)
      AND EXISTS (
          SELECT 1 FROM store_returns sr
          WHERE sr.sr_store_sk = 1 AND sr.sr_net_loss > 0
      )
)
SELECT
    cp_catalog_page_sk,
    cp_department,
    first_word_desc,
    num_orders,
    total_sales,
    warehouse_qty,
    sales_category
FROM final
ORDER BY total_sales DESC
LIMIT 100
