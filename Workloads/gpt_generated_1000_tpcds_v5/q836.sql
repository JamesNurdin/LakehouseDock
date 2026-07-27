WITH demo_returns AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_credit_rating,
        SUM(sr.sr_return_quantity) AS total_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_credit_rating
),
overall_avg AS (
    SELECT AVG(sr_return_amt) AS avg_return_amt FROM store_returns
)
SELECT *
FROM (
    SELECT
        dr.cd_gender AS gender,
        dr.cd_credit_rating AS credit_rating,
        CASE WHEN dr.total_net_loss > 2000 THEN 'Very High' ELSE 'High' END AS category,
        dr.total_qty AS metric_quantity,
        dr.total_return_amt AS metric_amount,
        oa.avg_return_amt AS overall_avg_return_amt
    FROM demo_returns dr
    CROSS JOIN overall_avg oa
    WHERE dr.total_net_loss > 1000
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_cdemo_sk = dr.cd_demo_sk
            AND sr2.sr_reversed_charge > 500
      )
    GROUP BY dr.cd_gender,
             dr.cd_credit_rating,
             CASE WHEN dr.total_net_loss > 2000 THEN 'Very High' ELSE 'High' END,
             dr.total_qty,
             dr.total_return_amt,
             oa.avg_return_amt
    HAVING SUM(dr.total_qty) > 10
    UNION ALL
    SELECT DISTINCT
        dr.cd_gender AS gender,
        dr.cd_credit_rating AS credit_rating,
        CASE WHEN dr.total_qty > 150 THEN 'Large Qty' ELSE 'Small Qty' END AS category,
        dr.total_qty AS metric_quantity,
        dr.total_return_amt AS metric_amount,
        oa.avg_return_amt AS overall_avg_return_amt
    FROM demo_returns dr
    CROSS JOIN overall_avg oa
    WHERE dr.total_qty > 30
      AND dr.cd_credit_rating IN ('Good', 'Low Risk')
) combined
ORDER BY gender, credit_rating, category
LIMIT 100
