WITH catalog_cte AS (
    SELECT
        'catalog' AS source,
        td.t_hour AS hour,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_fee > 20.00
      AND td.t_time BETWEEN 9 AND 18
),
web_cte AS (
    SELECT
        'web' AS source,
        td.t_hour AS hour,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE wr.wr_account_credit < 100.00
      AND td.t_hour IN (9,10,11,12,13,14,15,16,17,18)
)
SELECT
    source,
    hour,
    SUM(net_loss) AS total_net_loss
FROM (
    SELECT source, hour, net_loss FROM catalog_cte
    UNION ALL
    SELECT source, hour, net_loss FROM web_cte
) u
GROUP BY source, hour
ORDER BY source, hour
