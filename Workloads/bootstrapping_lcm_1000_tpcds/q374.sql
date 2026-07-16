SELECT
    d.d_year,
    CASE
        WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter,
    s.s_division_name,
    COUNT(DISTINCT cr.cr_item_sk) AS distinct_catalog_items,
    COUNT(DISTINCT sr.sr_item_sk) AS distinct_store_items,
    COUNT(DISTINCT wr.wr_item_sk) AS distinct_web_items,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(sr.sr_return_amt) AS store_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    AVG(cr.cr_return_quantity) AS avg_catalog_qty,
    AVG(sr.sr_return_quantity) AS avg_store_qty,
    AVG(wr.wr_return_quantity) AS avg_web_qty,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN 1 ELSE 0 END) AS catalog_positive_loss_cnt,
    SUM(CASE WHEN sr.sr_net_loss > 0 THEN 1 ELSE 0 END) AS store_positive_loss_cnt,
    SUM(CASE WHEN wr.wr_net_loss > 0 THEN 1 ELSE 0 END) AS web_positive_loss_cnt
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
    AND s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    CASE
        WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    s.s_division_name
HAVING (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) > 0
ORDER BY
    d.d_year,
    quarter,
    s.s_division_name
LIMIT 100
