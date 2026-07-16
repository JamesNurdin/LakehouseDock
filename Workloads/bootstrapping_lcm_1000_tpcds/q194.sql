WITH agg AS (
    SELECT
        d.d_year,
        w.w_warehouse_name,
        s.s_store_name,
        ws.web_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
     AND ws.web_close_date_sk = d.d_date_sk
    GROUP BY
        d.d_year,
        w.w_warehouse_name,
        s.s_store_name,
        ws.web_name
)
SELECT
    d_year,
    w_warehouse_name,
    s_store_name,
    web_name,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    return_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY net_loss_rank, total_net_loss DESC
LIMIT 100
