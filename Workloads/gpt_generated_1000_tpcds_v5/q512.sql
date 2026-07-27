WITH catalog_ret AS (
    SELECT
        'catalog' AS return_source,
        cr.cr_order_number AS order_number,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_quantity AS return_qty,
        cr.cr_return_amount AS return_amount,
        r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 50
      AND lower(r.r_reason_desc) LIKE '%not working%'
),
web_ret AS (
    SELECT
        'web' AS return_source,
        wr.wr_order_number AS order_number,
        wr.wr_item_sk AS item_sk,
        wr.wr_return_quantity AS return_qty,
        wr.wr_return_amt AS return_amount,
        r.r_reason_desc AS reason_desc
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > 50
      AND lower(r.r_reason_desc) LIKE '%not working%'
)
SELECT *
FROM catalog_ret
UNION ALL
SELECT *
FROM web_ret
ORDER BY return_amount DESC
LIMIT 100
