WITH
    sr_data AS (
        SELECT
            s.s_store_name,
            r.r_reason_desc,
            sr.sr_net_loss,
            c.c_customer_id,
            cd.cd_gender
        FROM store_returns sr
        FULL OUTER JOIN store s
            ON sr.sr_store_sk = s.s_store_sk
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        JOIN customer c
            ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON sr.sr_cdemo_sk = cd.cd_demo_sk
    ),
    wr_data AS (
        SELECT
            r.r_reason_desc,
            wr.wr_net_loss,
            cref.c_customer_id AS refunded_customer_id,
            cret.c_customer_id AS returning_customer_id,
            cdref.cd_gender AS refunded_gender,
            cdret.cd_gender AS returning_gender
        FROM web_returns wr
        JOIN reason r
            ON wr.wr_reason_sk = r.r_reason_sk
        JOIN customer cref
            ON wr.wr_refunded_customer_sk = cref.c_customer_sk
        JOIN customer_demographics cdref
            ON wr.wr_refunded_cdemo_sk = cdref.cd_demo_sk
        JOIN customer cret
            ON wr.wr_returning_customer_sk = cret.c_customer_sk
        JOIN customer_demographics cdret
            ON wr.wr_returning_cdemo_sk = cdret.cd_demo_sk
    )
SELECT
    sr.s_store_name,
    sr.r_reason_desc,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT sr.c_customer_id) AS distinct_store_customers,
    COUNT(DISTINCT wr.refunded_customer_id) AS distinct_refunded_customers,
    COUNT(DISTINCT wr.returning_customer_id) AS distinct_returning_customers
FROM sr_data sr
FULL OUTER JOIN wr_data wr
    ON sr.r_reason_desc = wr.r_reason_desc
GROUP BY
    sr.s_store_name,
    sr.r_reason_desc
ORDER BY
    total_store_net_loss DESC,
    sr.r_reason_desc
LIMIT 100
