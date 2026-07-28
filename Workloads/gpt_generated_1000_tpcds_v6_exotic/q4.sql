WITH customer_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        c.c_salutation,
        c.c_birth_year,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_net_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt
    FROM tpcds.customer c
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1930 AND 1975
      AND (c.c_email_address LIKE '%.com' OR c.c_email_address LIKE '%.org')
      AND (sr.sr_reversed_charge > 0 OR wr.wr_return_quantity > 5)
    GROUP BY
        c.c_customer_sk,
        c.c_email_address,
        c.c_salutation,
        c.c_birth_year
)
SELECT
    cr.c_salutation,
    cr.c_birth_year,
    AVG(cr.store_net_loss) AS avg_store_net_loss,
    AVG(cr.web_net_loss) AS avg_web_net_loss,
    SUM(cr.store_return_cnt) AS total_store_returns,
    SUM(cr.web_return_cnt) AS total_web_returns
FROM customer_returns cr
WHERE cr.store_return_cnt > 0 OR cr.web_return_cnt > 0
GROUP BY cr.c_salutation, cr.c_birth_year
HAVING SUM(cr.store_return_cnt) > 0
ORDER BY avg_store_net_loss DESC
LIMIT 100
