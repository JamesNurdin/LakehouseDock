WITH store_agg AS (
    SELECT
        sr.sr_reason_sk AS reason_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        MIN(t.t_time) AS earliest_return_time
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_am_pm = 'PM'
    GROUP BY sr.sr_reason_sk
),
web_agg AS (
    SELECT
        wr.wr_reason_sk AS reason_sk,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        MAX(t.t_time) AS latest_return_time
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE t.t_am_pm = 'PM'
      AND regexp_like(wp.wp_url, '.*promo.*')
    GROUP BY wr.wr_reason_sk
),
reason_filtered AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        CONCAT('Reason: ', r.r_reason_desc) AS reason_label
    FROM reason r
    WHERE regexp_like(r.r_reason_desc, '^Package.*')
      AND r.r_reason_desc LIKE '%damaged%'
)
SELECT
    rf.r_reason_sk,
    rf.reason_label,
    COALESCE(sa.store_net_loss, 0) AS store_net_loss,
    COALESCE(wa.web_net_loss, 0) AS web_net_loss,
    (COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) AS total_net_loss,
    sa.distinct_tickets,
    wa.distinct_orders,
    CASE
        WHEN (COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) >
            (SELECT AVG(total_loss) FROM (
                SELECT SUM(sr.sr_net_loss) AS total_loss FROM store_returns sr
                UNION ALL
                SELECT SUM(wr.wr_net_loss) AS total_loss FROM web_returns wr
            ) sub)
        THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_category,
    (SELECT COUNT(DISTINCT wp.wp_url) FROM web_page wp WHERE wp.wp_type LIKE 'article%') AS distinct_article_urls
FROM reason_filtered rf
LEFT JOIN store_agg sa ON rf.r_reason_sk = sa.reason_sk
LEFT JOIN web_agg wa ON rf.r_reason_sk = wa.reason_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    JOIN web_page wp2 ON wr2.wr_web_page_sk = wp2.wp_web_page_sk
    WHERE wr2.wr_reason_sk = rf.r_reason_sk
      AND wp2.wp_type LIKE 'article%'
)
ORDER BY total_net_loss DESC, rf.r_reason_sk
LIMIT 100
