SELECT
    r_main.r_reason_desc,
    s_main.s_store_name,
    cd_ret.cd_gender,
    CASE WHEN cd_ret.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_label,
    SUM(sr.sr_return_amt) AS total_return_amt,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns,
    AVG(sr.sr_store_credit) AS avg_store_credit,
    SUM(CASE WHEN sr.sr_net_loss > 0 THEN sr.sr_net_loss ELSE 0 END) AS total_positive_net_loss,
    SUM(t.metric) AS sum_store_metric,
    COUNT(t.metric) AS metric_rows
FROM
    store_returns sr
    INNER JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd_ret
        ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    LEFT JOIN customer_demographics cd_cur
        ON c.c_current_cdemo_sk = cd_cur.cd_demo_sk
    INNER JOIN store s_main
        ON sr.sr_store_sk = s_main.s_store_sk
    INNER JOIN store s_alt
        ON sr.sr_store_sk = s_alt.s_store_sk
    RIGHT OUTER JOIN reason r_main
        ON sr.sr_reason_sk = r_main.r_reason_sk
    INNER JOIN reason r_alt
        ON sr.sr_reason_sk = r_alt.r_reason_sk
    CROSS JOIN LATERAL (
        SELECT ARRAY[s_main.s_number_employees, s_main.s_floor_space] AS metrics
    ) la
    CROSS JOIN UNNEST(la.metrics) AS t(metric)
WHERE
    EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_return_quantity > 10
    )
GROUP BY
    r_main.r_reason_desc,
    s_main.s_store_name,
    cd_ret.cd_gender,
    CASE WHEN cd_ret.cd_gender = 'M' THEN 'Male' ELSE 'Female' END
ORDER BY
    total_return_amt DESC
LIMIT 100
