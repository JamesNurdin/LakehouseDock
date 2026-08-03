WITH agg_returns AS (
    SELECT
        cr_warehouse_sk,
        cr_catalog_page_sk,
        COUNT(*) AS cnt_returns,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_quantity) AS avg_return_qty,
        MIN(cr_return_amount) AS min_return_amount,
        MAX(cr_return_amount) AS max_return_amount
    FROM catalog_returns
    WHERE cr_store_credit > 50
      AND cr_reversed_charge < 200
      AND cr_return_quantity BETWEEN 1 AND 10
      AND cr_returning_cdemo_sk IN (413251, 268615)
      AND cr_returning_cdemo_sk <> 999999
      AND cr_returned_date_sk > 2450900
    GROUP BY cr_warehouse_sk, cr_catalog_page_sk
),
sampled_warehouse AS (
    SELECT *
    FROM warehouse
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_suite_number,
    cp.cp_department,
    cp.cp_type,
    ar.cnt_returns,
    ar.total_return_amount,
    ar.avg_return_qty,
    ar.min_return_amount,
    ar.max_return_amount,
    dim.val
FROM agg_returns ar
JOIN sampled_warehouse w
    ON ar.cr_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp
    ON ar.cr_catalog_page_sk = cp.cp_catalog_page_sk
CROSS JOIN (VALUES VARCHAR 'X', VARCHAR 'Y') AS dim(val)
WHERE w.w_suite_number NOT IN ('Suite 350', 'Suite 260')
  AND cp.cp_end_date_sk > 2450900
  AND cp.cp_catalog_page_id LIKE 'AAAAAAA%'
  AND w.w_state = 'CA'
  AND w.w_gmt_offset BETWEEN -5 AND 5
  AND cp.cp_department = 'Electronics'
  AND w.w_city NOT IN (SELECT w2.w_city FROM warehouse w2 WHERE w2.w_zip LIKE '9%')
  AND w.w_warehouse_sk NOT IN (
        SELECT cr_warehouse_sk
        FROM catalog_returns
        WHERE cr_store_credit > 100
      )
LIMIT 100
