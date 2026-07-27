WITH catalog_agg AS (
    SELECT
        td.t_shift AS shift,
        CASE WHEN cr.cr_net_loss > 100 THEN 'high' ELSE 'low' END AS loss_category,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM catalog_returns AS cr
    JOIN time_dim AS td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 6 AND 12
    GROUP BY
        td.t_shift,
        CASE WHEN cr.cr_net_loss > 100 THEN 'high' ELSE 'low' END
),
store_agg AS (
    SELECT
        td.t_shift AS shift,
        CASE WHEN sr.sr_net_loss > 100 THEN 'high' ELSE 'low' END AS loss_category,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM store_returns AS sr
    JOIN time_dim AS td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 6 AND 12
    GROUP BY
        td.t_shift,
        CASE WHEN sr.sr_net_loss > 100 THEN 'high' ELSE 'low' END
)
SELECT
    shift,
    loss_category,
    total_net_loss,
    cnt_returns
FROM catalog_agg
UNION ALL
SELECT
    shift,
    loss_category,
    total_net_loss,
    cnt_returns
FROM store_agg
ORDER BY shift, loss_category
LIMIT 100
