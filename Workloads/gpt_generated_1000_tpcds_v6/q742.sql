WITH base_returns AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_returned_date_sk,
        sr.sr_net_loss,
        cd.cd_gender,
        ca.ca_gmt_offset
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_gmt_offset BETWEEN -10.00 AND -5.00
)
SELECT
    gender,
    period,
    total_loss,
    returns_cnt,
    loss_category
FROM (
    SELECT
        cd_gender AS gender,
        'Period1' AS period,
        SUM(sr_net_loss) AS total_loss,
        COUNT(*) AS returns_cnt,
        CASE WHEN SUM(sr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM base_returns
    WHERE sr_returned_date_sk BETWEEN 2450900 AND 2451200
    GROUP BY cd_gender
    UNION ALL
    SELECT
        cd_gender AS gender,
        'Period2' AS period,
        SUM(sr_net_loss) AS total_loss,
        COUNT(*) AS returns_cnt,
        CASE WHEN SUM(sr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM base_returns
    WHERE sr_returned_date_sk BETWEEN 2451300 AND 2451600
    GROUP BY cd_gender
) AS combined
ORDER BY total_loss DESC
LIMIT 100
