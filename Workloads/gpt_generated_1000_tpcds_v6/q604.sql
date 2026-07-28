WITH catalog_ret AS (
    SELECT DISTINCT
        c.c_customer_id,
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%customer%'
),
web_ret AS (
    SELECT DISTINCT
        c.c_customer_id,
        wr.wr_returned_date_sk AS return_date_sk,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%customer%'
)
SELECT
    customer_id,
    SUM(net_loss) AS total_net_loss,
    COUNT(*) AS return_events
FROM (
    SELECT c_customer_id AS customer_id, net_loss FROM catalog_ret
    UNION ALL
    SELECT c_customer_id AS customer_id, net_loss FROM web_ret
) combined
GROUP BY customer_id
ORDER BY total_net_loss DESC
LIMIT 10
