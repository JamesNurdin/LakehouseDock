WITH combined AS (
    SELECT
        'store' AS source,
        td.t_hour,
        sr.sr_store_sk AS entity_id,
        SUM(sr.sr_net_loss) AS net_loss,
        SUM(sr.sr_return_quantity) AS return_qty,
        AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    GROUP BY td.t_hour, sr.sr_store_sk
    UNION ALL
    SELECT
        'web' AS source,
        td.t_hour,
        wp.wp_web_page_sk AS entity_id,
        SUM(wr.wr_net_loss) AS net_loss,
        SUM(wr.wr_return_quantity) AS return_qty,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY td.t_hour, wp.wp_web_page_sk
)
SELECT
    source,
    t_hour,
    entity_id,
    net_loss,
    return_qty,
    avg_return_amt_inc_tax,
    loss_rank,
    loss_category
FROM (
    SELECT
        source,
        t_hour,
        entity_id,
        net_loss,
        return_qty,
        avg_return_amt_inc_tax,
        RANK() OVER (PARTITION BY source, t_hour ORDER BY net_loss DESC) AS loss_rank,
        CASE
            WHEN net_loss > 20000 THEN 'CRITICAL'
            WHEN net_loss > 10000 THEN 'HIGH'
            WHEN net_loss > 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_category
    FROM combined
) q
WHERE loss_rank <= 3
ORDER BY source, t_hour, loss_rank
