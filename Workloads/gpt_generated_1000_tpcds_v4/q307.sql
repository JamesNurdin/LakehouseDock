WITH store_ret AS (
    SELECT DISTINCT
        c.c_customer_id,
        'store' AS return_type,
        sr.sr_net_loss AS total_loss,
        CASE WHEN sr.sr_fee > 70 THEN 1 ELSE 0 END AS high_fee_flag
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_amt > 50
      AND sr.sr_fee < 80
),
web_ret AS (
    SELECT DISTINCT
        c.c_customer_id,
        'web' AS return_type,
        wr.wr_net_loss AS total_loss,
        CASE WHEN wr.wr_fee > 70 THEN 1 ELSE 0 END AS high_fee_flag
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wr.wr_return_amt > 50
      AND wr.wr_fee < 80
)
SELECT *
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM web_ret
) AS combined
ORDER BY total_loss DESC, high_fee_flag DESC
LIMIT 100
