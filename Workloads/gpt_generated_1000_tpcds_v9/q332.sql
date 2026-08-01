WITH demo_agg AS (
    SELECT
        cd_demo_sk,
        cd_education_status,
        cd_dep_college_count
    FROM customer_demographics
    WHERE cd_education_status IN ('College', 'Advanced Degree', '2 yr Degree')
)
SELECT
    education_status,
    source,
    total_amount,
    transaction_count,
    avg_amount,
    related_total,
    latest_sk,
    ROW_NUMBER() OVER (PARTITION BY education_status ORDER BY total_amount DESC) AS rank_by_amount
FROM (
    SELECT
        d.cd_education_status AS education_status,
        'store_returns' AS source,
        SUM(sr.sr_net_loss) AS total_amount,
        COUNT(*) AS transaction_count,
        AVG(sr.sr_net_loss) AS avg_amount,
        (
            SELECT SUM(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_cdemo_sk = d.cd_demo_sk
        ) AS related_total,
        l.latest_return_sk AS latest_sk
    FROM demo_agg d
    JOIN store_returns sr
        ON sr.sr_cdemo_sk = d.cd_demo_sk
    CROSS JOIN LATERAL (
        SELECT sr_lr.sr_returned_date_sk AS latest_return_sk
        FROM store_returns sr_lr
        WHERE sr_lr.sr_cdemo_sk = d.cd_demo_sk
        ORDER BY sr_lr.sr_returned_date_sk DESC
        LIMIT 1
    ) l
    WHERE sr.sr_return_amt > 10
      AND d.cd_dep_college_count >= 1
    GROUP BY d.cd_education_status, d.cd_demo_sk, l.latest_return_sk
    HAVING SUM(sr.sr_net_loss) > 100
    UNION ALL
    SELECT
        d.cd_education_status AS education_status,
        'web_sales' AS source,
        SUM(ws.ws_net_profit) AS total_amount,
        COUNT(*) AS transaction_count,
        AVG(ws.ws_net_profit) AS avg_amount,
        (
            SELECT SUM(ws2.ws_ext_list_price)
            FROM web_sales ws2
            WHERE ws2.ws_bill_cdemo_sk = d.cd_demo_sk
        ) AS related_total,
        l.latest_sold_sk AS latest_sk
    FROM demo_agg d
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = d.cd_demo_sk
    CROSS JOIN LATERAL (
        SELECT ws_ws.ws_sold_date_sk AS latest_sold_sk
        FROM web_sales ws_ws
        WHERE ws_ws.ws_bill_cdemo_sk = d.cd_demo_sk
        ORDER BY ws_ws.ws_sold_date_sk DESC
        LIMIT 1
    ) l
    WHERE ws.ws_ext_list_price > 500
      AND d.cd_dep_college_count >= 1
    GROUP BY d.cd_education_status, d.cd_demo_sk, l.latest_sold_sk
    HAVING SUM(ws.ws_net_profit) > 50
) t
ORDER BY education_status, source
