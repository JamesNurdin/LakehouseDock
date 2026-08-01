WITH sales_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM
        store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN inventory inv TABLESAMPLE BERNOULLI (10) ON inv.inv_item_sk = i.i_item_sk
    WHERE
        i.i_rec_end_date >= DATE '2000-01-01'
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_category
),
web_ret_items AS (
    SELECT DISTINCT
        i.i_item_sk,
        i.i_item_id,
        i.i_category
    FROM
        web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE
        i.i_class_id IN (12, 15, 16)
),
intersect_items AS (
    SELECT i_item_sk FROM sales_items
    INTERSECT
    SELECT i_item_sk FROM web_ret_items
),
full_center_warehouse AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_order_number,
        cr.cr_return_amount,
        r.r_reason_desc,
        cc.cc_name,
        w.w_warehouse_name
    FROM
        catalog_returns cr
        FULL OUTER JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        cr.cr_return_amount > 0
)
SELECT DISTINCT
    si.i_item_id,
    si.i_category,
    si.total_sales,
    si.sales_rank,
    (SELECT COUNT(*) FROM catalog_returns cr2 WHERE cr2.cr_item_sk = si.i_item_sk) AS total_catalog_returns,
    CASE WHEN inv_flag.inv_item_sk IS NOT NULL THEN 'In_Inventory' ELSE 'No_Inventory' END AS inventory_flag
FROM
    sales_items si
    LEFT JOIN (
        SELECT inv_item_sk FROM inventory TABLESAMPLE BERNOULLI (10)
    ) inv_flag ON inv_flag.inv_item_sk = si.i_item_sk
WHERE
    si.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
    AND EXISTS (
        SELECT 1 FROM full_center_warehouse fcw
        WHERE fcw.cr_item_sk = si.i_item_sk
          AND fcw.cr_return_amount > 5
    )
ORDER BY
    si.total_sales DESC
LIMIT 100
