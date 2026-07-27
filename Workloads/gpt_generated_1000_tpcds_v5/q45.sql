WITH combined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_reason_sk,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        d.d_year,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001                                 -- filter 1: specific year
      AND r.r_reason_desc LIKE '%model%'                 -- filter 2: reason containing the word "model"
      AND cr.cr_net_loss > 500.00                        -- filter 3: minimum catalog loss
),
agg AS (
    SELECT
        d_year,
        r_reason_desc,
        SUM(cr_net_loss) AS catalog_loss,
        SUM(sr_net_loss) AS store_loss,
        SUM(cr_net_loss) + SUM(sr_net_loss) AS total_loss,
        GROUPING(d_year) AS g_year,
        GROUPING(r_reason_desc) AS g_reason
    FROM combined
    GROUP BY ROLLUP (d_year, r_reason_desc)
    HAVING SUM(cr_net_loss) + SUM(sr_net_loss) > 1000.00   -- keep only groups with substantial loss
)
SELECT
    d_year,
    r_reason_desc,
    catalog_loss,
    store_loss,
    total_loss,
    ROW_NUMBER() OVER (ORDER BY total_loss DESC) AS loss_rank,
    g_year,
    g_reason
FROM agg
ORDER BY loss_rank
