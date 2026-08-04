WITH cc_with_city AS (
    SELECT cc_call_center_sk
    FROM call_center
    WHERE cc_city LIKE 'R%'
),
cr_filtered AS (
    SELECT
        cr_returned_time_sk,
        cr_reason_sk,
        SUM(cr_return_amount) AS total_cr_amount,
        COUNT(*) AS cnt_cr
    FROM catalog_returns
    WHERE cr_call_center_sk IN (SELECT cc_call_center_sk FROM cc_with_city)
    GROUP BY cr_returned_time_sk, cr_reason_sk
),
wr_filtered AS (
    SELECT
        wr_returned_time_sk,
        wr_reason_sk,
        SUM(wr_return_amt) AS total_wr_amount,
        COUNT(*) AS cnt_wr
    FROM web_returns
    GROUP BY wr_returned_time_sk, wr_reason_sk
),
joined AS (
    SELECT
        COALESCE(cr.cr_returned_time_sk, wr.wr_returned_time_sk) AS time_sk,
        COALESCE(cr.cr_reason_sk, wr.wr_reason_sk) AS reason_sk,
        cr.total_cr_amount,
        wr.total_wr_amount,
        cr.cnt_cr,
        wr.cnt_wr
    FROM cr_filtered cr
    FULL OUTER JOIN wr_filtered wr
        ON cr.cr_returned_time_sk = wr.wr_returned_time_sk
        AND cr.cr_reason_sk = wr.wr_reason_sk
),
reason_in_cr AS (
    SELECT DISTINCT cr_reason_sk AS reason_sk FROM catalog_returns
),
reason_in_wr AS (
    SELECT DISTINCT wr_reason_sk AS reason_sk FROM web_returns
),
reason_only_in_cr AS (
    SELECT reason_sk FROM reason_in_cr
    EXCEPT
    SELECT reason_sk FROM reason_in_wr
),
reason_filtered AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(?i)(service|product|parts)', 1) AS key_term
    FROM reason r
    WHERE regexp_like(r.r_reason_desc, '(?i)service|product|parts')
),
final AS (
    SELECT
        j.time_sk,
        td.t_hour,
        r.r_reason_desc,
        j.total_cr_amount,
        j.total_wr_amount,
        (j.total_cr_amount - j.total_wr_amount) AS diff_amount,
        j.cnt_cr,
        j.cnt_wr
    FROM joined j
    LEFT JOIN time_dim td ON j.time_sk = td.t_time_sk
    LEFT JOIN reason_filtered r ON j.reason_sk = r.r_reason_sk
    INNER JOIN reason_only_in_cr rc ON j.reason_sk = rc.reason_sk
)
SELECT *
FROM final
WHERE diff_amount IS NOT NULL
ORDER BY diff_amount DESC
LIMIT 100
