WITH catalog_part AS (
    SELECT
        cr.cr_order_number AS order_number,
        'catalog' AS source,
        r.r_reason_desc AS reason_desc,
        CASE WHEN regexp_like(r.r_reason_desc, '[0-9]{2,}') THEN 'ContainsNumber' ELSE 'NoNumber' END AS reason_num_flag,
        SUM(cr.cr_return_amount) AS total_amount,
        COUNT(*) AS cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE r.r_reason_desc LIKE '%damaged%'
      AND regexp_like(r.r_reason_desc, '[0-9]{2,}')
      AND w.w_zip LIKE '38%'
      AND CONCAT(w.w_city, ', ', w.w_state) LIKE '%Ville%'
    GROUP BY cr.cr_order_number, r.r_reason_desc
),
web_part AS (
    SELECT
        wr.wr_order_number AS order_number,
        'web' AS source,
        r.r_reason_desc AS reason_desc,
        CASE WHEN regexp_like(r.r_reason_desc, '[0-9]{2,}') THEN 'ContainsNumber' ELSE 'NoNumber' END AS reason_num_flag,
        SUM(wr.wr_return_amt) AS total_amount,
        COUNT(*) AS cnt
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%damaged%'
      AND regexp_like(r.r_reason_desc, '[0-9]{2,}')
      AND substr(CAST(wr.wr_refunded_customer_sk AS varchar), 1, 1) = '1'
    GROUP BY wr.wr_order_number, r.r_reason_desc
)
SELECT
    combined.order_number,
    combined.source,
    combined.reason_desc,
    combined.reason_num_flag,
    combined.total_amount,
    combined.cnt
FROM (
    SELECT order_number, source, reason_desc, reason_num_flag, total_amount, cnt FROM catalog_part
    UNION
    SELECT order_number, source, reason_desc, reason_num_flag, total_amount, cnt FROM web_part
) AS combined
WHERE combined.order_number NOT IN (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1000
)
ORDER BY combined.total_amount DESC
LIMIT 100
