WITH agg AS (
    SELECT
        i.i_manager_id AS manager_id,
        i.i_color AS color,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM web_returns wr
    JOIN item i
      ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date <= DATE '2000-10-27'
      AND i.i_rec_end_date >= DATE '2000-10-27'
      AND i.i_color IN ('red', 'pink')
      AND wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY GROUPING SETS ((i.i_manager_id, i.i_color), (i.i_manager_id))
    HAVING SUM(wr.wr_net_loss) > 0
)
SELECT
    manager_id,
    color,
    distinct_orders,
    total_return_qty,
    total_net_loss,
    avg_return_qty,
    RANK() OVER (PARTITION BY manager_id ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
