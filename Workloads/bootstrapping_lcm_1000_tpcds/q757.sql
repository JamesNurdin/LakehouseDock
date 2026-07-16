WITH store_return_agg AS (
    SELECT
        s.s_store_id,
        d_ret.d_year,
        d_ret.d_month_seq,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS store_net_loss,
        MIN(d_store_closed.d_date) AS store_closed_date,
        MAX(d_store_closed.d_year) AS store_closed_year
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY s.s_store_id, d_ret.d_year, d_ret.d_month_seq, r.r_reason_desc
),
catalog_return_agg AS (
    SELECT
        d_ret.d_year,
        d_ret.d_month_seq,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY d_ret.d_year, d_ret.d_month_seq, r.r_reason_desc
)
SELECT
    COALESCE(sr.s_store_id, 'ALL_STORES') AS store_id,
    sr.d_year,
    sr.d_month_seq,
    sr.r_reason_desc,
    sr.store_net_loss,
    cr.catalog_net_loss,
    sr.store_net_loss + cr.catalog_net_loss AS total_net_loss,
    sr.store_closed_date,
    sr.store_closed_year
FROM store_return_agg sr
FULL OUTER JOIN catalog_return_agg cr
    ON sr.d_year = cr.d_year
    AND sr.d_month_seq = cr.d_month_seq
    AND sr.r_reason_desc = cr.r_reason_desc
ORDER BY sr.d_year, sr.d_month_seq, sr.r_reason_desc
