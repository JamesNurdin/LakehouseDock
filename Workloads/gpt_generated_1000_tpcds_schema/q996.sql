WITH ticket_exclusions AS (
    SELECT sr_ticket_number
    FROM store_returns
    WHERE sr_fee < 30
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
    WHERE sr_fee > 60
),
base AS (
    SELECT
        sr.sr_store_sk,
        CONCAT('Hour_', CAST(t.t_hour AS VARCHAR)) AS hour_label,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
        (SELECT AVG(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_store_sk = sr.sr_store_sk) AS avg_store_return,
        sr.sr_ticket_number
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_ticket_number NOT IN (SELECT sr_ticket_number FROM ticket_exclusions)
      AND t.t_time_id LIKE 'AAAAAAA%'
      AND regexp_like(t.t_time_id, '^A{8}I')
    GROUP BY sr.sr_store_sk, t.t_hour, sr.sr_ticket_number
    HAVING SUM(sr.sr_return_amt) > 100
),
base2 AS (
    SELECT
        sr.sr_store_sk,
        CONCAT('Hour_', CAST(t.t_hour AS VARCHAR)) AS hour_label,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
        (SELECT AVG(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_store_sk = sr.sr_store_sk) AS avg_store_return,
        sr.sr_ticket_number
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_ticket_number NOT IN (SELECT sr_ticket_number FROM ticket_exclusions)
      AND t.t_second BETWEEN 10 AND 18
      AND regexp_extract(t.t_time_id, '(I|A)', 1) = 'A'
    GROUP BY sr.sr_store_sk, t.t_hour, sr.sr_ticket_number
    HAVING SUM(sr.sr_return_amt) > 100
)
SELECT
    store_sk,
    hour_label,
    total_return_amt,
    total_net_loss,
    loss_category,
    avg_store_return
FROM (
    SELECT
        sr_store_sk AS store_sk,
        hour_label,
        total_return_amt,
        total_net_loss,
        loss_category,
        avg_store_return
    FROM base
    UNION
    SELECT
        sr_store_sk AS store_sk,
        hour_label,
        total_return_amt,
        total_net_loss,
        loss_category,
        avg_store_return
    FROM base2
) AS combined
ORDER BY total_return_amt DESC
LIMIT 100
