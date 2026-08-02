WITH agg_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        w.w_warehouse_name,
        d.d_year,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
        AND ws.web_close_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_shift = 'first'
      AND w.w_city IN ('Liberty', 'Salem')
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cr.cr_order_number
            AND cr2.cr_warehouse_sk <> cr.cr_warehouse_sk
      )
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        w.w_warehouse_name,
        d.d_year
    HAVING COUNT(DISTINCT cr.cr_item_sk) > 5
)
SELECT DISTINCT
    s_store_id,
    s_store_name,
    w_warehouse_name,
    d_year,
    total_net_loss,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank
FROM agg_returns
ORDER BY loss_rank
LIMIT 10
