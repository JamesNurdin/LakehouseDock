SELECT
    d.d_year,
    d.d_month_seq,
    SUM(cr.cr_net_loss) AS catalog_total_net_loss,
    SUM(wr.wr_net_loss) AS web_total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    AVG(cr.cr_return_amount) AS avg_catalog_return_amount,
    AVG(wr.wr_return_amt_inc_tax) AS avg_web_return_amount_inc_tax,
    SUM(s.s_floor_space) AS total_closed_store_floor_space,
    SUM(ws.web_tax_percentage) AS total_web_site_tax_percentage,
    COUNT(DISTINCT s.s_store_sk) AS num_closed_stores,
    COUNT(DISTINCT ws.web_site_sk) AS num_open_web_sites,
    CASE
        WHEN (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) <> 0
            THEN (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) / NULLIF(COUNT(cr.cr_return_quantity) + COUNT(wr.wr_return_quantity), 0)
        ELSE NULL
    END AS avg_loss_per_return
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state = ws.web_state
GROUP BY d.d_year, d.d_month_seq
ORDER BY d.d_year, d.d_month_seq
LIMIT 100
