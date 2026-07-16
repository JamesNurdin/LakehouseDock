SELECT
    dd.d_year,
    dd.d_month_seq,
    s.s_state,
    CASE WHEN dd.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(DISTINCT cr.cr_order_number)                     AS catalog_return_count,
    COUNT(DISTINCT wr.wr_order_number)                     AS web_return_count,
    COALESCE(SUM(cr.cr_return_amount), 0)                  AS total_catalog_return_amount,
    COALESCE(SUM(wr.wr_return_amt), 0)                     AS total_web_return_amount,
    COALESCE(SUM(cr.cr_net_loss), 0)                       AS total_catalog_net_loss,
    COALESCE(SUM(wr.wr_net_loss), 0)                       AS total_web_net_loss,
    CASE
        WHEN SUM(wr.wr_net_loss) = 0 THEN NULL
        ELSE SUM(cr.cr_net_loss) / SUM(wr.wr_net_loss)
    END                                                    AS catalog_to_web_net_loss_ratio,
    COALESCE(SUM(cr.cr_fee), 0)                            AS total_catalog_fee,
    COALESCE(SUM(wr.wr_fee), 0)                            AS total_web_fee,
    AVG(cr.cr_return_quantity)                            AS avg_catalog_return_quantity,
    AVG(wr.wr_return_quantity)                            AS avg_web_return_quantity,
    COUNT(DISTINCT s.s_store_id)                           AS stores_closed_on_date
FROM catalog_returns cr
JOIN date_dim dd
    ON cr.cr_returned_date_sk = dd.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = dd.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd.d_date_sk
WHERE dd.d_year BETWEEN 2000 AND 2005
GROUP BY
    dd.d_year,
    dd.d_month_seq,
    s.s_state,
    CASE WHEN dd.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END
ORDER BY
    dd.d_year,
    dd.d_month_seq,
    s.s_state,
    day_type
LIMIT 100
