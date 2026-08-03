WITH bought AS (
    SELECT c.c_customer_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
),
returned AS (
    SELECT sr.sr_customer_sk AS c_customer_sk
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%Did not like%'
)
SELECT
    cust_id,
    source,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY cust_id) AS rn
FROM (
    SELECT c_customer_sk AS cust_id, 'BoughtAndReturned' AS source
    FROM (
        SELECT c_customer_sk FROM bought
        INTERSECT
        SELECT c_customer_sk FROM returned
    )
    UNION ALL
    SELECT c_customer_sk AS cust_id, 'BoughtOnly' AS source
    FROM (
        SELECT c_customer_sk FROM bought
        EXCEPT
        SELECT c_customer_sk FROM returned
    )
) AS final_set
ORDER BY source, rn
LIMIT 100
