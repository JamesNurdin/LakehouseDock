WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand,
        COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM inventory
    WHERE inv_quantity_on_hand > 200
    GROUP BY inv_date_sk, inv_warehouse_sk
),
joined AS (
    SELECT
        dd.d_week_seq,
        ia.inv_warehouse_sk,
        SUM(ia.total_qty_on_hand) AS sum_qty,
        SUM(wr.wr_return_amt) AS sum_return_amt,
        SUM(wr.wr_net_loss) AS sum_net_loss
    FROM date_dim dd
    JOIN inv_agg ia
        ON ia.inv_date_sk = dd.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE dd.d_week_seq BETWEEN 10 AND 20
      AND dd.d_current_year = 'Y'
      AND wr.wr_return_amt > 10
      AND wr.wr_net_loss > 0
      AND dd.d_date_sk NOT IN (
          SELECT DISTINCT inv_date_sk
          FROM inventory
          WHERE inv_quantity_on_hand < 0
      )
    GROUP BY ROLLUP (dd.d_week_seq, ia.inv_warehouse_sk)
)
SELECT
    d_week_seq,
    inv_warehouse_sk,
    sum_qty,
    sum_return_amt,
    sum_net_loss,
    ROW_NUMBER() OVER (ORDER BY sum_return_amt DESC NULLS LAST) AS global_row_num,
    RANK() OVER (PARTITION BY d_week_seq ORDER BY sum_net_loss DESC NULLS LAST) AS weekly_net_loss_rank,
    CASE
        WHEN sum_net_loss > 10000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS loss_category,
    (SELECT AVG(wr_return_amt) FROM web_returns) AS avg_return_amt_overall
FROM joined
ORDER BY d_week_seq NULLS LAST, inv_warehouse_sk
LIMIT 100
