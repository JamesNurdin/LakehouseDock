WITH catalog_loss AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'catalog' AS return_source,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'OVERNIGHT'
      AND d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
store_loss AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'store' AS return_source,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    d_year,
    d_month_seq,
    return_source,
    total_net_loss
FROM catalog_loss
UNION ALL
SELECT
    d_year,
    d_month_seq,
    return_source,
    total_net_loss
FROM store_loss
ORDER BY d_year, d_month_seq, return_source
