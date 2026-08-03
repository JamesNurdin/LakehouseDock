WITH date_filter AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
)
SELECT
    df.d_year AS year,
    sm.sm_carrier AS carrier,
    SUM(cr.cr_net_loss) AS total_net_loss,
    CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS avg_net_loss
FROM catalog_returns cr
JOIN date_filter df ON cr.cr_returned_date_sk = df.d_date_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cr.cr_ship_mode_sk IN (
    SELECT sm2.sm_ship_mode_sk
    FROM ship_mode sm2
    WHERE sm2.sm_carrier = 'ZOUROS'
)
GROUP BY df.d_year, sm.sm_carrier

UNION ALL

SELECT
    df.d_year AS year,
    CAST(NULL AS varchar) AS carrier,
    SUM(wr.wr_net_loss) AS total_net_loss,
    CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    (SELECT AVG(wr2.wr_net_loss) FROM web_returns wr2) AS avg_net_loss
FROM web_returns wr
JOIN date_filter df ON wr.wr_returned_date_sk = df.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM ship_mode sm3
    WHERE sm3.sm_code = 'AIR'
)
GROUP BY df.d_year
ORDER BY year, carrier, loss_category
