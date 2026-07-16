WITH agg AS (
    SELECT
        d.d_year,
        s.s_division_name,
        ws.web_market_manager,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(cr.cr_fee) AS avg_catalog_fee,
        AVG(wr.wr_fee) AS avg_web_fee
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND s.s_state = 'CA'
      AND ws.web_state = 'CA'
    GROUP BY d.d_year, s.s_division_name, ws.web_market_manager
    HAVING SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 10000
)
SELECT
    a.d_year,
    a.s_division_name,
    a.web_market_manager,
    a.catalog_return_orders,
    a.web_return_orders,
    a.total_catalog_net_loss,
    a.total_web_net_loss,
    a.total_return_amount,
    a.avg_catalog_fee,
    a.avg_web_fee,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY (a.total_catalog_net_loss + a.total_web_net_loss) DESC) AS loss_rank
FROM agg a
ORDER BY a.total_catalog_net_loss DESC
LIMIT 100
