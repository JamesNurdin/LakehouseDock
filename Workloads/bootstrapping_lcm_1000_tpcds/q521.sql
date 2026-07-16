SELECT
    dd.d_year,
    CASE
        WHEN dd.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN dd.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN dd.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter,
    s.s_state,
    s.s_city,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_return_amount + cr.cr_return_tax + cr.cr_return_ship_cost) AS total_catalog_return_cost,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_return_inc_tax,
    SUM(wr.wr_return_amt_inc_tax) AS total_web_return_inc_tax,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) /
        NULLIF(
            (SUM(cr.cr_return_amount + cr.cr_return_tax + cr.cr_return_ship_cost) +
             SUM(sr.sr_return_amt_inc_tax) +
             SUM(wr.wr_return_amt_inc_tax)),
            0) AS net_loss_to_return_ratio
FROM catalog_returns cr
JOIN date_dim dd
    ON cr.cr_returned_date_sk = dd.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = dd.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = dd.d_date_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
   AND s.s_closed_date_sk = dd.d_date_sk
GROUP BY
    dd.d_year,
    CASE
        WHEN dd.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN dd.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN dd.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    s.s_state,
    s.s_city
HAVING
    (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) > 1000
ORDER BY
    dd.d_year DESC,
    quarter,
    total_catalog_net_loss DESC
LIMIT 100
