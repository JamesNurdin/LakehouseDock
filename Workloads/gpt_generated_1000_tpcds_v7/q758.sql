WITH catalog_subset AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        w.w_city AS city,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CAST('catalog' AS varchar) AS source
    FROM tpcds.catalog_returns cr
    JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'monthly'
      AND w.w_suite_number = 'Suite 80  '
      AND r.r_reason_desc LIKE '%damaged%'
    GROUP BY r.r_reason_desc, w.w_city
),
web_subset AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        w.w_city AS city,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CAST('web' AS varchar) AS source
    FROM tpcds.web_returns wr
    JOIN tpcds.reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.inventory inv ON wr.wr_item_sk = inv.inv_item_sk
    JOIN tpcds.warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_suite_number = 'Suite 80  '
      AND r.r_reason_desc LIKE '%damaged%'
    GROUP BY r.r_reason_desc, w.w_city
)
SELECT * FROM catalog_subset
UNION ALL
SELECT * FROM web_subset
LIMIT 100
