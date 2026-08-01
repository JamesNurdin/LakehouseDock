SELECT
    d_year,
    return_type,
    total_net_loss,
    total_return_quantity,
    avg_return_amount,
    loss_category
FROM (
    SELECT
        d.d_year AS d_year,
        'Catalog' AS return_type,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count >= 2
    GROUP BY d.d_year

    UNION ALL

    SELECT
        d.d_year AS d_year,
        'Store' AS return_type,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        AVG(sr.sr_return_amt) AS avg_return_amount,
        CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_state = 'CA'
      AND hd.hd_vehicle_count >= 0
    GROUP BY d.d_year
) AS combined
ORDER BY d_year DESC, return_type
LIMIT 100
