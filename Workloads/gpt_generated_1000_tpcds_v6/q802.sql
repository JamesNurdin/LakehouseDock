WITH store_ret AS (
    SELECT
        c.c_customer_id,
        c.c_birth_country,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(sr.sr_net_loss) > 500 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM tpcds.store_returns sr
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'BAHAMAS'
      AND sr.sr_reversed_charge > 100
    GROUP BY c.c_customer_id, c.c_birth_country
),
web_ret AS (
    SELECT
        c.c_customer_id,
        c.c_birth_country,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(wr.wr_net_loss) > 300 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM tpcds.web_returns wr
    JOIN tpcds.customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'KOREA'
      AND wr.wr_return_tax > 20
    GROUP BY c.c_customer_id, c.c_birth_country
)
SELECT
    c_customer_id,
    c_birth_country,
    total_loss,
    return_cnt,
    loss_category
FROM store_ret
UNION ALL
SELECT
    c_customer_id,
    c_birth_country,
    total_loss,
    return_cnt,
    loss_category
FROM web_ret
ORDER BY total_loss DESC, loss_category
LIMIT 100
