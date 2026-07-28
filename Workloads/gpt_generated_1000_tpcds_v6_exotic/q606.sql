WITH catalog_agg AS (
    SELECT
        cd.cd_gender AS gender,
        SUM(cr.cr_return_amount) AS total_return_amount,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount > 100
    GROUP BY cd.cd_gender
    HAVING SUM(cr.cr_return_amount) > 10000
),
store_agg AS (
    SELECT
        cd.cd_gender AS gender,
        SUM(sr.sr_return_amt) AS total_return_amount,
        'store' AS source
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_return_amt > 50
    GROUP BY cd.cd_gender
    HAVING SUM(sr.sr_return_amt) > 8000
),
combined AS (
    SELECT gender, total_return_amount, source FROM catalog_agg
    UNION ALL
    SELECT gender, total_return_amount, source FROM store_agg
)
SELECT
    c.gender,
    c.total_return_amount,
    c.source
FROM combined c
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    JOIN customer_demographics cd2 ON cs2.cs_bill_cdemo_sk = cd2.cd_demo_sk
    WHERE cd2.cd_gender = c.gender
)
ORDER BY c.total_return_amount DESC
LIMIT 100
