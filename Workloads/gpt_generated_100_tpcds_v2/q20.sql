WITH demographic_sales AS (
    SELECT
        cd.cd_gender,
        cd.cd_credit_rating,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_quantity > 10
        AND cd.cd_credit_rating IN ('Good', 'Low Risk')
    GROUP BY cd.cd_gender, cd.cd_credit_rating
)
SELECT
    ds.cd_gender,
    ds.cd_credit_rating,
    ds.total_net_profit,
    ds.transaction_count,
    avg_total.avg_total_net_profit
FROM demographic_sales ds
CROSS JOIN (
    SELECT AVG(total_net_profit) AS avg_total_net_profit
    FROM demographic_sales
) avg_total
WHERE ds.total_net_profit > avg_total.avg_total_net_profit
ORDER BY ds.total_net_profit DESC
