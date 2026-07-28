WITH base_cte AS (
    SELECT
        sr.sr_reason_sk,
        r.r_reason_desc,
        ss.ss_store_sk,
        SUM(sr.sr_refunded_cash) AS total_refunded,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_refunded_cash > 100
      AND ss.ss_store_sk IN (794, 688, 14)
      AND r.r_reason_id = 'AAAAAAAAEBAAAAAA'
    GROUP BY sr.sr_reason_sk, r.r_reason_desc, ss.ss_store_sk
),
agg_cte AS (
    SELECT
        r_reason_desc,
        ss_store_sk,
        total_refunded,
        total_sales,
        distinct_tickets,
        total_refunded / NULLIF(total_sales, 0) AS refund_rate,
        ROW_NUMBER() OVER (PARTITION BY r_reason_desc ORDER BY total_refunded DESC) AS rn_refund_rank
    FROM base_cte
)
SELECT DISTINCT
    r_reason_desc,
    ss_store_sk,
    total_refunded,
    total_sales,
    refund_rate,
    rn_refund_rank
FROM agg_cte
WHERE rn_refund_rank <= 5
  AND total_refunded > (SELECT AVG(total_refunded) FROM base_cte)
ORDER BY total_refunded DESC
LIMIT 100
