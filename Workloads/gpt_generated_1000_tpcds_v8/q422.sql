WITH filtered_returns AS (
    SELECT *
    FROM web_returns
    WHERE wr_return_tax > 10.00
      AND wr_reversed_charge < 500.00
      AND wr_return_quantity >= 1
      AND wr_return_amt BETWEEN 20 AND 200
      AND wr_returned_date_sk BETWEEN 2450000 AND 2452000
),
reason_keys_to_exclude AS (
    SELECT r_reason_sk
    FROM reason
    WHERE r_reason_desc LIKE '%warranty%'
),
reason_keys_to_include AS (
    SELECT r_reason_sk
    FROM reason
    WHERE r_reason_desc NOT LIKE '%warranty%'
),
included_reason_keys AS (
    SELECT r_reason_sk
    FROM reason_keys_to_include
    EXCEPT
    SELECT r_reason_sk
    FROM reason_keys_to_exclude
),
joined_data AS (
    SELECT
        fr.wr_returned_date_sk,
        fr.wr_return_amt,
        fr.wr_return_tax,
        fr.wr_return_quantity,
        fr.wr_reversed_charge,
        r.r_reason_sk,
        r.r_reason_id,
        r.r_reason_desc
    FROM filtered_returns fr
    RIGHT OUTER JOIN reason r
        ON fr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_sk IN (SELECT r_reason_sk FROM included_reason_keys)
),
lateral_aggregated AS (
    SELECT
        jd.*,
        la.total_return_amt_for_reason
    FROM joined_data jd
    LEFT JOIN LATERAL (
        SELECT SUM(wr_return_amt) AS total_return_amt_for_reason
        FROM web_returns wr
        WHERE wr.wr_reason_sk = jd.r_reason_sk
    ) la ON TRUE
),
full_joined AS (
    SELECT
        la.r_reason_id,
        la.r_reason_desc,
        la.r_reason_sk,
        la.wr_returned_date_sk,
        la.wr_return_amt,
        la.wr_return_tax,
        la.wr_return_quantity,
        la.wr_reversed_charge,
        la.total_return_amt_for_reason,
        nr.r_reason_id AS nr_reason_id,
        nr.r_reason_desc AS nr_reason_desc
    FROM lateral_aggregated la
    FULL OUTER JOIN (
        SELECT r_reason_sk, r_reason_id, r_reason_desc
        FROM reason
        WHERE r_reason_sk NOT IN (SELECT DISTINCT wr_reason_sk FROM web_returns)
    ) nr
        ON la.r_reason_sk = nr.r_reason_sk
),
final_with_window AS (
    SELECT
        *,
        SUM(wr_return_amt) OVER (
            PARTITION BY r_reason_sk
            ORDER BY wr_returned_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_sum_return_amt
    FROM full_joined
)
SELECT
    COALESCE(r_reason_id, nr_reason_id) AS reason_id,
    COALESCE(r_reason_desc, nr_reason_desc) AS reason_desc,
    COUNT(*) AS return_rows,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(wr_return_tax) AS avg_return_tax,
    MIN(wr_return_amt) AS min_return_amount,
    MAX(wr_return_amt) AS max_return_amount,
    MAX(running_sum_return_amt) AS max_running_sum,
    total_return_amt_for_reason
FROM final_with_window
WHERE EXISTS (
    SELECT 1
    FROM reason r2
    WHERE r2.r_reason_sk = final_with_window.r_reason_sk
      AND r2.r_reason_desc LIKE '%service%'
)
GROUP BY
    COALESCE(r_reason_id, nr_reason_id),
    COALESCE(r_reason_desc, nr_reason_desc),
    total_return_amt_for_reason
ORDER BY total_return_amount DESC
LIMIT 100
