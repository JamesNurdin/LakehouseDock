WITH agg_returns AS (
    SELECT
        sr_reason_sk,
        SUM(sr_return_amt)        AS total_return_amt,
        SUM(sr_net_loss)          AS total_net_loss,
        COUNT(*)                  AS cnt_returns
    FROM store_returns
    WHERE sr_return_amt > 20
      AND sr_return_quantity > 1
      AND sr_return_tax < 5
    GROUP BY sr_reason_sk
)
SELECT *
FROM (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        a.total_return_amt,
        a.total_net_loss,
        a.cnt_returns,
        (
            SELECT MAX(sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_reason_sk = r.r_reason_sk
        )                               AS max_return_amt,
        CASE WHEN a.total_net_loss > 1000 THEN 'High loss' ELSE 'Low loss' END AS loss_category,
        RANK() OVER (ORDER BY a.total_return_amt DESC)               AS revenue_rank
    FROM agg_returns a
    RIGHT OUTER JOIN reason r
        ON a.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%missing%'
       OR r.r_reason_desc LIKE '%exchange%'
       OR EXISTS (
           SELECT 1
           FROM store_returns sr3
           WHERE sr3.sr_reason_sk = r.r_reason_sk
             AND sr3.sr_refunded_cash > 500
       )

    UNION

    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        a.total_return_amt,
        a.total_net_loss,
        a.cnt_returns,
        (
            SELECT MAX(sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_reason_sk = r.r_reason_sk
        )                               AS max_return_amt,
        CASE WHEN a.total_net_loss > 500 THEN 'Moderate loss' ELSE 'Minor loss' END AS loss_category,
        DENSE_RANK() OVER (ORDER BY a.total_return_amt DESC)          AS revenue_rank
    FROM agg_returns a
    RIGHT OUTER JOIN reason r
        ON a.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%does not work%'
      AND a.cnt_returns IS NOT NULL
      AND a.total_return_amt > 0
) AS combined
ORDER BY revenue_rank
LIMIT 100
