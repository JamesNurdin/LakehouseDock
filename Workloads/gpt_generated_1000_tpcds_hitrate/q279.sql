WITH full_item AS (
    SELECT
        sr.sr_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        sr.sr_return_amt_inc_tax,
        CASE WHEN sr.sr_return_amt_inc_tax > 5000 THEN 'HIGH' ELSE 'LOW' END AS amt_category
    FROM store_returns sr
    FULL OUTER JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_brand_id IN (19, 34)
      AND sr.sr_return_amt_inc_tax IS NOT NULL
),
full_reason AS (
    SELECT
        sr.sr_reason_sk,
        r.r_reason_desc,
        sr.sr_store_credit,
        CASE WHEN sr.sr_store_credit > 500 THEN 'BIG' ELSE 'SMALL' END AS credit_level
    FROM store_returns sr
    FULL OUTER JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id LIKE 'AAAAAAA%'
)
SELECT * FROM (
    SELECT
        'Item' AS source,
        i_brand AS brand,
        amt_category AS category,
        SUM(sr_return_amt_inc_tax) AS total_amount,
        COUNT(*) AS transaction_cnt,
        CAST(NULL AS varchar) AS reason_desc,
        CAST(NULL AS varchar) AS credit_level
    FROM full_item
    GROUP BY i_brand, amt_category
    HAVING SUM(sr_return_amt_inc_tax) > 1000

    UNION ALL

    SELECT
        'Reason' AS source,
        CAST(NULL AS varchar) AS brand,
        CAST(NULL AS varchar) AS category,
        SUM(sr_store_credit) AS total_amount,
        COUNT(*) AS transaction_cnt,
        r_reason_desc,
        credit_level
    FROM full_reason
    GROUP BY r_reason_desc, credit_level
    HAVING SUM(sr_store_credit) > 200
) AS combined
ORDER BY total_amount DESC
OFFSET 0 ROWS
LIMIT 100
