WITH catalog_reason AS (
    SELECT DISTINCT r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_net_loss > 1000
),
web_reason AS (
    SELECT DISTINCT r.r_reason_desc AS reason_desc
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_net_loss > 1000
)
SELECT reason_desc
FROM catalog_reason
INTERSECT
SELECT reason_desc
FROM web_reason
ORDER BY reason_desc
LIMIT 100
