WITH aggregated AS (
    SELECT
        d.d_quarter_seq,
        s.s_market_manager,
        s.s_market_desc,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_orders,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        SUM(cr.cr_return_tax) AS total_catalog_tax,
        SUM(wr.wr_return_tax) AS total_web_tax,
        SUM(cr.cr_return_quantity) AS total_catalog_quantity,
        SUM(wr.wr_return_quantity) AS total_web_quantity,
        AVG(cr.cr_return_amt_inc_tax) AS avg_catalog_return_amt_inc_tax,
        AVG(wr.wr_return_amt_inc_tax) AS avg_web_return_amt_inc_tax,
        CASE 
            WHEN SUM(wr.wr_net_loss) = 0 THEN NULL
            ELSE SUM(cr.cr_net_loss) / SUM(wr.wr_net_loss)
        END AS catalog_to_web_net_loss_ratio
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_quarter_seq, s.s_market_manager, s.s_market_desc
    HAVING SUM(cr.cr_net_loss) > 0 OR SUM(wr.wr_net_loss) > 0
)
SELECT
    a.d_quarter_seq,
    a.s_market_manager,
    a.s_market_desc,
    a.catalog_orders,
    a.web_orders,
    a.total_catalog_net_loss,
    a.total_web_net_loss,
    a.total_catalog_tax,
    a.total_web_tax,
    a.total_catalog_quantity,
    a.total_web_quantity,
    a.avg_catalog_return_amt_inc_tax,
    a.avg_web_return_amt_inc_tax,
    a.catalog_to_web_net_loss_ratio,
    ROW_NUMBER() OVER (PARTITION BY a.d_quarter_seq ORDER BY a.total_catalog_net_loss DESC) AS catalog_loss_rank
FROM aggregated a
ORDER BY a.d_quarter_seq, a.s_market_manager
LIMIT 100
