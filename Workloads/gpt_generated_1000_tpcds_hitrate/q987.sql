WITH
    sal_dim AS (
        SELECT DISTINCT c_salutation
        FROM customer
        LIMIT 5
    ),
    store_agg AS (
        SELECT
            cust.c_customer_id,
            cust.c_last_name,
            COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amt,
            COALESCE(SUM(sr.sr_net_loss), 0) AS total_net_loss
        FROM customer AS cust
        FULL OUTER JOIN store_returns AS sr
            ON sr.sr_customer_sk = cust.c_customer_sk
        WHERE (
                sr.sr_customer_sk IN (
                    SELECT c_customer_sk
                    FROM customer
                    WHERE c_birth_year = 1985
                )
            )
            OR sr.sr_customer_sk IS NULL
        GROUP BY cust.c_customer_id, cust.c_last_name
    ),
    web_agg AS (
        SELECT
            cust.c_customer_id,
            cust.c_last_name,
            COALESCE(SUM(wr.wr_refunded_cash), 0) AS total_refunded_cash,
            COALESCE(SUM(wr.wr_net_loss), 0) AS total_net_loss
        FROM customer AS cust
        FULL OUTER JOIN web_returns AS wr
            ON wr.wr_refunded_customer_sk = cust.c_customer_sk
        WHERE (
                wr.wr_refunded_customer_sk IN (
                    SELECT c_customer_sk
                    FROM customer
                    WHERE c_birth_month = 7
                )
            )
            OR wr.wr_refunded_customer_sk IS NULL
        GROUP BY cust.c_customer_id, cust.c_last_name
    ),
    union_all AS (
        SELECT
            c_customer_id,
            c_last_name,
            total_return_amt AS amount,
            CASE WHEN total_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_category,
            'Store' AS source
        FROM store_agg
        UNION ALL
        SELECT
            c_customer_id,
            c_last_name,
            total_refunded_cash AS amount,
            CASE WHEN total_net_loss > 500 THEN 'High' ELSE 'Low' END AS loss_category,
            'Web' AS source
        FROM web_agg
    )
SELECT
    u.c_customer_id,
    u.c_last_name,
    u.amount,
    u.loss_category,
    u.source,
    d.c_salutation
FROM union_all AS u
CROSS JOIN sal_dim AS d
ORDER BY u.loss_category DESC, u.amount DESC
LIMIT 100
