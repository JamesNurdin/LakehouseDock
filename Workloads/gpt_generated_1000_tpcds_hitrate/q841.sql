WITH
    filtered_returns AS (
        SELECT *
        FROM store_returns
        WHERE sr_return_ship_cost > 0
          AND sr_return_quantity > 1
          AND sr_return_amt > 0
    ),
    agg_returns AS (
        SELECT
            sr_reason_sk,
            SUM(sr_return_amt) AS total_return_amt,
            SUM(sr_return_ship_cost) AS total_ship_cost,
            COUNT(*) AS return_cnt
        FROM filtered_returns
        GROUP BY sr_reason_sk
    ),
    except_keys AS (
        SELECT sr_reason_sk FROM store_returns
        EXCEPT
        SELECT r_reason_sk FROM reason
    ),
    joined AS (
        SELECT
            r.r_reason_sk,
            r.r_reason_id,
            r.r_reason_desc,
            ar.total_return_amt,
            ar.total_ship_cost,
            ar.return_cnt,
            CASE
                WHEN ar.total_return_amt > 1000 THEN 'High'
                WHEN ar.total_return_amt BETWEEN 500 AND 1000 THEN 'Medium'
                ELSE 'Low'
            END AS return_category
        FROM reason r
        FULL OUTER JOIN agg_returns ar
            ON r.r_reason_sk = ar.sr_reason_sk
    )
SELECT
    j.r_reason_sk,
    j.r_reason_id,
    j.r_reason_desc,
    j.total_return_amt,
    j.total_ship_cost,
    j.return_cnt,
    j.return_category,
    ROW_NUMBER() OVER (ORDER BY COALESCE(j.total_return_amt, 0) DESC) AS rn,
    CASE WHEN j.r_reason_sk IS NULL THEN 'Missing Reason' ELSE 'Present' END AS reason_status,
    ek.sr_reason_sk AS missing_in_reason_sk
FROM joined j
LEFT JOIN except_keys ek
    ON j.r_reason_sk = ek.sr_reason_sk
WHERE (j.r_reason_desc LIKE '%color%' OR j.r_reason_desc LIKE '%product%')
  AND j.total_ship_cost IS NOT NULL
  AND j.return_cnt IS NOT NULL
ORDER BY j.total_return_amt DESC
OFFSET 20
LIMIT 100
