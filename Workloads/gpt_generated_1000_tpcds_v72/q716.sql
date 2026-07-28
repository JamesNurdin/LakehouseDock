WITH combined AS (
    -- First pattern: Deluxe or Premium items with reason containing "service"
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        regexp_extract(i.i_item_id, '(\\d+)', 1) AS item_number
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(i.i_product_name, '(Deluxe|Premium)')
      AND r.r_reason_desc LIKE '%service%'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id
    HAVING SUM(sr.sr_return_amt) > 1000

    UNION ALL

    -- Second pattern: Basic items with reason containing "size"
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        regexp_extract(i.i_item_id, '(\\d+)', 1) AS item_number
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE i.i_product_name LIKE '%Basic%'
      AND r.r_reason_desc LIKE '%size%'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id
    HAVING SUM(sr.sr_return_amt) > 800
)
SELECT
    combined.c_customer_id,
    combined.customer_name,
    combined.total_return_amt,
    combined.return_cnt,
    combined.item_number,
    (
        SELECT MAX(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = combined.c_customer_sk
          AND sr2.sr_return_amt > 0
    ) AS max_single_return,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM store_returns sr3
            JOIN reason r3 ON sr3.sr_reason_sk = r3.r_reason_sk
            WHERE sr3.sr_customer_sk = combined.c_customer_sk
              AND regexp_like(r3.r_reason_desc, '.*(service|size).*')
        ) THEN 'Yes'
        ELSE 'No'
    END AS has_service_or_size_reason
FROM combined
ORDER BY combined.total_return_amt DESC
LIMIT 100
