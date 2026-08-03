WITH catalog_cte AS (
    SELECT
        cr.cr_item_sk,
        i.i_product_name,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reason_sk,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 50
      AND cr.cr_reason_sk IN (SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%damage%')
),
store_cte AS (
    SELECT
        sr.sr_item_sk,
        i.i_product_name,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_reason_sk,
        r.r_reason_desc
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 50
      AND EXISTS (SELECT 1 FROM reason r2 WHERE r2.r_reason_sk = sr.sr_reason_sk AND r2.r_reason_desc LIKE '%damage%')
),
full_outer AS (
    SELECT
        COALESCE(c.r_reason_desc, s.r_reason_desc) AS reason_desc,
        COALESCE(c.i_product_name, s.i_product_name) AS product_name,
        COALESCE(c.cr_return_amount, 0) + COALESCE(s.sr_return_amt, 0) AS total_return_amount,
        COALESCE(c.cr_return_quantity, 0) + COALESCE(s.sr_return_quantity, 0) AS total_return_quantity,
        (SELECT avg(cr_return_amount) FROM catalog_returns) AS avg_catalog_return_amount
    FROM catalog_cte c
    FULL OUTER JOIN store_cte s
        ON c.cr_item_sk = s.sr_item_sk
),
cross_part AS (
    SELECT
        rd.r_reason_desc AS reason_desc,
        NULL AS product_name,
        ra.return_amount AS total_return_amount,
        NULL AS total_return_quantity,
        (SELECT avg(cr_return_amount) FROM catalog_returns) AS avg_catalog_return_amount
    FROM (
        SELECT r_reason_sk, r_reason_desc
        FROM reason
        LIMIT 5
    ) rd
    CROSS JOIN (
        SELECT DISTINCT return_amount
        FROM (
            SELECT cr_return_amount AS return_amount FROM catalog_returns
            UNION ALL
            SELECT sr_return_amt AS return_amount FROM store_returns
        ) all_returns
        WHERE return_amount > 30
    ) ra
)
SELECT *
FROM (
    SELECT * FROM full_outer
    UNION ALL
    SELECT * FROM cross_part
) combined
ORDER BY reason_desc, product_name
LIMIT 100
