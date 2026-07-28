/* goal: Identify customers with the highest total net loss from damage‑related returns across catalog and store channels, including their full name, number of channels affected, a sample reason, and a rank by loss. */
WITH unified_returns AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        'catalog' AS channel,
        cr.cr_net_loss AS loss,
        r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
       OR r.r_reason_desc LIKE '%damage%'
    UNION
    SELECT
        sr.sr_customer_sk AS customer_sk,
        'store' AS channel,
        sr.sr_net_loss AS loss,
        r.r_reason_desc AS reason_desc
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
       OR r.r_reason_desc LIKE '%damage%'
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    SUM(u.loss) AS total_loss,
    COUNT(DISTINCT u.channel) AS channels_affected,
    SUBSTRING(MIN(u.reason_desc), 1, 20) AS exemplar_reason,
    RANK() OVER (ORDER BY SUM(u.loss) DESC) AS loss_rank,
    (SELECT AVG(loss) FROM unified_returns) AS avg_loss_per_return
FROM unified_returns u
JOIN customer c ON u.customer_sk = c.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_customer_sk = c.c_customer_sk
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
)
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    CONCAT(c.c_first_name, ' ', c.c_last_name)
ORDER BY total_loss DESC
LIMIT 100
