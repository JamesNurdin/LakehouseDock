WITH fo AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_reason_sk,
            cr.cr_return_amount,
            d.d_year,
            r.r_reason_desc
        FROM catalog_returns cr
        FULL OUTER JOIN date_dim d
            ON cr.cr_returned_date_sk = d.d_date_sk
        LEFT JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        WHERE d.d_year BETWEEN 1999 AND 2001
    ),
    ranked AS (
        SELECT
            cr_returned_date_sk,
            cr_reason_sk,
            cr_return_amount,
            d_year,
            r_reason_desc,
            ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY cr_return_amount DESC) AS rn
        FROM fo
        WHERE cr_return_amount IS NOT NULL
    ),
    top_k AS (
        SELECT *
        FROM ranked
        WHERE rn <= 5
    ),
    set1 AS (
        SELECT cr_returned_date_sk
        FROM catalog_returns
        WHERE cr_return_amount > 1000
    ),
    set2 AS (
        SELECT cr_returned_date_sk
        FROM catalog_returns
        WHERE cr_return_tax > 0
    ),
    intersect_keys AS (
        SELECT cr_returned_date_sk FROM set1
        INTERSECT
        SELECT cr_returned_date_sk FROM set2
    )
SELECT
    t.cr_returned_date_sk,
    t.cr_reason_sk,
    t.cr_return_amount,
    t.d_year,
    t.r_reason_desc,
    t.rn
FROM top_k t
WHERE EXISTS (
        SELECT 1
        FROM intersect_keys ik
        WHERE ik.cr_returned_date_sk = t.cr_returned_date_sk
    )
UNION ALL
SELECT
    CAST(NULL AS INTEGER) AS cr_returned_date_sk,
    CAST(NULL AS INTEGER) AS cr_reason_sk,
    CAST(NULL AS DECIMAL(7,2)) AS cr_return_amount,
    d.d_year,
    ws.web_name AS r_reason_desc,
    1 AS rn
FROM web_site ws
JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2000
ORDER BY d_year DESC, cr_return_amount DESC
