WITH first AS (
    SELECT r.r_reason_id,
           r.r_reason_desc,
           SUM(cr.cr_return_amount) AS total_return_amount,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_fee > 30
    GROUP BY r.r_reason_id, r.r_reason_desc
),
second AS (
    SELECT r.r_reason_id,
           r.r_reason_desc,
           SUM(cr.cr_return_amount) AS total_return_amount,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 5
    GROUP BY r.r_reason_id, r.r_reason_desc
)
SELECT t.r_reason_id,
       t.r_reason_desc,
       t.total_return_amount,
       t.return_cnt
FROM (
    SELECT r.r_reason_id,
           r.r_reason_desc,
           SUM(cr.cr_return_amount) AS total_return_amount,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_fee > 30
    GROUP BY r.r_reason_id, r.r_reason_desc

    UNION ALL

    SELECT r.r_reason_id,
           r.r_reason_desc,
           SUM(cr.cr_return_amount) AS total_return_amount,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 5
    GROUP BY r.r_reason_id, r.r_reason_desc
) t
ORDER BY t.total_return_amount DESC, t.return_cnt DESC
LIMIT 100
