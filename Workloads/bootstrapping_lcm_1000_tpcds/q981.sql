WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        w.web_site_id,
        p.p_promo_id,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d_ret.d_date_sk
        AND w.web_close_date_sk = d_ret.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_ret.d_date_sk
        AND p.p_end_date_sk = d_ret.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        w.web_site_id,
        p.p_promo_id,
        d_ret.d_year,
        d_ret.d_month_seq
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.web_site_id,
    a.p_promo_id,
    a.d_year,
    a.d_month_seq,
    a.total_net_loss,
    a.return_count,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_net_loss DESC) AS loss_rank_by_store
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100
