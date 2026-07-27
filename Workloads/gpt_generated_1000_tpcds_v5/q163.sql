WITH catalog_ret AS (
    SELECT
        d.d_date AS return_date,
        cr.cr_net_loss AS net_loss,
        'catalog' AS source,
        sm.sm_carrier AS carrier,
        ROW_NUMBER() OVER (ORDER BY cr.cr_net_loss DESC) AS loss_rank
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
),
web_ret AS (
    SELECT
        d.d_date AS return_date,
        wr.wr_net_loss AS net_loss,
        'web' AS source,
        CAST(NULL AS varchar) AS carrier,
        ROW_NUMBER() OVER (ORDER BY wr.wr_net_loss DESC) AS loss_rank
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT *
FROM (
    SELECT return_date, net_loss, source, carrier, loss_rank FROM catalog_ret
    UNION ALL
    SELECT return_date, net_loss, source, carrier, loss_rank FROM web_ret
) combined
ORDER BY net_loss DESC, return_date
LIMIT 100
