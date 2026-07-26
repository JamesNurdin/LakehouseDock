WITH store_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        SUM(sr.sr_return_amt) AS store_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
web_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        SUM(wr.wr_return_amt) AS web_return_amt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
page_creation_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT wp.wp_web_page_sk) AS pages_created,
        AVG(wp.wp_char_count) AS avg_char_count_created
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
page_access_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT wp.wp_web_page_sk) AS pages_accessed,
        AVG(wp.wp_link_count) AS avg_link_count_accessed
    FROM web_page wp
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    sm.d_year,
    sm.d_month_seq,
    sm.store_net_loss,
    wm.web_net_loss,
    (sm.store_net_loss + wm.web_net_loss) AS total_net_loss,
    LAG(sm.store_net_loss + wm.web_net_loss) OVER (ORDER BY sm.d_year, sm.d_month_seq) AS prev_month_net_loss,
    CASE
        WHEN LAG(sm.store_net_loss + wm.web_net_loss) OVER (ORDER BY sm.d_year, sm.d_month_seq) IS NULL THEN NULL
        WHEN LAG(sm.store_net_loss + wm.web_net_loss) OVER (ORDER BY sm.d_year, sm.d_month_seq) = 0 THEN NULL
        ELSE ((sm.store_net_loss + wm.web_net_loss) - LAG(sm.store_net_loss + wm.web_net_loss) OVER (ORDER BY sm.d_year, sm.d_month_seq)) / LAG(sm.store_net_loss + wm.web_net_loss) OVER (ORDER BY sm.d_year, sm.d_month_seq) * 100
    END AS mom_growth_pct,
    CASE
        WHEN ((sm.store_net_loss + wm.web_net_loss) - LAG(sm.store_net_loss + wm.web_net_loss) OVER (ORDER BY sm.d_year, sm.d_month_seq)) > 0 THEN 'Increasing'
        WHEN ((sm.store_net_loss + wm.web_net_loss) - LAG(sm.store_net_loss + wm.web_net_loss) OVER (ORDER BY sm.d_year, sm.d_month_seq)) < 0 THEN 'Decreasing'
        ELSE 'Stable'
    END AS growth_trend,
    DENSE_RANK() OVER (ORDER BY (sm.store_net_loss + wm.web_net_loss) DESC) AS loss_rank,
    COALESCE(pc.pages_created, 0) AS pages_created,
    COALESCE(pa.pages_accessed, 0) AS pages_accessed,
    COALESCE(pc.avg_char_count_created, 0) AS avg_char_count_created,
    COALESCE(pa.avg_link_count_accessed, 0) AS avg_link_count_accessed
FROM store_month sm
JOIN web_month wm ON sm.d_year = wm.d_year AND sm.d_month_seq = wm.d_month_seq
LEFT JOIN page_creation_month pc ON sm.d_year = pc.d_year AND sm.d_month_seq = pc.d_month_seq
LEFT JOIN page_access_month pa ON sm.d_year = pa.d_year AND sm.d_month_seq = pa.d_month_seq
WHERE sm.d_year >= 2020
ORDER BY sm.d_year, sm.d_month_seq
