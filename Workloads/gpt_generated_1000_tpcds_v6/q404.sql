WITH high_loss AS (
    SELECT r.r_reason_desc,
           SUM(sr.sr_return_amt_inc_tax) AS total_inc_tax,
           COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
           CASE WHEN SUM(sr.sr_net_loss) > 2000 THEN 'Very High Loss' ELSE 'High Loss' END AS loss_category
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_net_loss > 300
    GROUP BY r.r_reason_desc
),
low_loss AS (
    SELECT r.r_reason_desc,
           SUM(sr.sr_return_amt_inc_tax) AS total_inc_tax,
           COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
           CASE WHEN AVG(sr.sr_return_amt_inc_tax) > 500 THEN 'Expensive Return' ELSE 'Regular Return' END AS loss_category
    FROM (
        SELECT DISTINCT sr_reason_sk,
                        sr_ticket_number,
                        sr_return_amt_inc_tax,
                        sr_net_loss
        FROM store_returns
        WHERE sr_net_loss < 100
    ) sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
)
SELECT *
FROM high_loss
UNION ALL
SELECT *
FROM low_loss
ORDER BY total_inc_tax DESC
LIMIT 100
