WITH catalog_agg AS (
    SELECT
        'catalog' AS return_type,
        t.t_hour AS hour,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_loss,
        CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_time BETWEEN 12 AND 18
    GROUP BY t.t_hour
),
store_agg AS (
    SELECT
        'store' AS return_type,
        t.t_hour AS hour,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_loss,
        CASE WHEN SUM(sr.sr_return_amt) > 500 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_time BETWEEN 12 AND 18
      AND sr.sr_return_tax > 5
    GROUP BY t.t_hour
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM store_agg
ORDER BY hour, return_type
LIMIT 100
