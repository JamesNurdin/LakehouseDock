WITH combined AS (
    SELECT
        s.s_store_id,
        s.s_city,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE
            WHEN SUM(sr.sr_net_loss) > 10000 THEN 'High Loss'
            WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss'
            ELSE 'Profit'
        END AS loss_category,
        'Smith' AS manager_group
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_market_manager = 'David Smith'
      AND s.s_street_type = 'Pkwy'
    GROUP BY s.s_store_id, s.s_city
    HAVING SUM(sr.sr_return_amt_inc_tax) > 5000

    UNION ALL

    SELECT
        s.s_store_id,
        s.s_city,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE
            WHEN SUM(sr.sr_net_loss) > 10000 THEN 'High Loss'
            WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss'
            ELSE 'Profit'
        END AS loss_category,
        'Wilson' AS manager_group
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_market_manager = 'Michael Wilson'
      AND s.s_street_type = 'Lane'
    GROUP BY s.s_store_id, s.s_city
    HAVING SUM(sr.sr_return_amt_inc_tax) > 5000
)
SELECT
    combined.s_store_id,
    combined.s_city,
    combined.total_return_inc_tax,
    combined.total_net_loss,
    combined.loss_category,
    combined.manager_group
FROM combined
ORDER BY combined.total_return_inc_tax DESC
LIMIT 100
