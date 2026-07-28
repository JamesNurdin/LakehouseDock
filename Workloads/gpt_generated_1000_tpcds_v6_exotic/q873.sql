WITH catalog_data AS (
    SELECT DISTINCT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.r_reason_desc,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc IN ('Gift exchange', 'Stopped working')
      AND c.c_birth_country = 'MONACO'
),
store_data AS (
    SELECT DISTINCT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.r_reason_desc,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc IN ('Gift exchange', 'Stopped working')
      AND c.c_birth_country = 'MONACO'
)
SELECT
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.r_reason_desc,
    SUM(cd.net_loss) AS total_net_loss
FROM (
    SELECT c_customer_id, c_first_name, c_last_name, r_reason_desc, cr_net_loss AS net_loss
    FROM catalog_data
    UNION ALL
    SELECT c_customer_id, c_first_name, c_last_name, r_reason_desc, sr_net_loss AS net_loss
    FROM store_data
) cd
GROUP BY
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
