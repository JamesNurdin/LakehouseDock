WITH
    returns_reason AS (
        SELECT
            cr.cr_warehouse_sk,
            cr.cr_return_amount,
            r.r_reason_desc
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    ),
    warehouse_sales AS (
        SELECT
            w.w_warehouse_sk,
            w.w_city,
            ws.ws_ext_sales_price,
            w.w_suite_number
        FROM web_sales ws
        RIGHT OUTER JOIN warehouse w
            ON ws.ws_warehouse_sk = w.w_warehouse_sk
    ),
    filtered_returns AS (
        SELECT
            cr_warehouse_sk,
            SUM(cr_return_amount) AS total_return_amount
        FROM returns_reason
        WHERE regexp_like(r_reason_desc, '(?i)size|warranty')
        GROUP BY cr_warehouse_sk
    ),
    filtered_sales AS (
        SELECT
            w_warehouse_sk,
            SUM(ws_ext_sales_price) AS total_sales
        FROM warehouse_sales
        WHERE w_suite_number LIKE 'Suite %'
          AND regexp_extract(w_suite_number, 'Suite (\\w+)', 1) IS NOT NULL
        GROUP BY w_warehouse_sk
    ),
    intersect_keys AS (
        SELECT cr_warehouse_sk AS warehouse_sk FROM filtered_returns
        INTERSECT
        SELECT w_warehouse_sk FROM filtered_sales
    ),
    except_keys AS (
        SELECT w_warehouse_sk FROM filtered_sales
        EXCEPT
        SELECT cr_warehouse_sk FROM filtered_returns
    ),
    union_all AS (
        SELECT cr_warehouse_sk AS warehouse_sk, total_return_amount AS metric FROM filtered_returns
        UNION
        SELECT w_warehouse_sk AS warehouse_sk, total_sales AS metric FROM filtered_sales
    )
SELECT
    i.warehouse_sk,
    COALESCE(r.total_return_amount, 0)   AS total_return_amount,
    COALESCE(s.total_sales, 0)           AS total_sales,
    u.metric                             AS union_metric
FROM intersect_keys i
LEFT JOIN filtered_returns r ON i.warehouse_sk = r.cr_warehouse_sk
LEFT JOIN filtered_sales   s ON i.warehouse_sk = s.w_warehouse_sk
LEFT JOIN union_all        u ON i.warehouse_sk = u.warehouse_sk
ORDER BY total_return_amount DESC, total_sales DESC
LIMIT 100
