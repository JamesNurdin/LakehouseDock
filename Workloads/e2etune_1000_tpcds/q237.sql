WITH brand_hour_agg AS (
    SELECT
        i.i_brand,
        t.t_hour,
        COUNT(*) AS num_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        SUM(sr.sr_return_quantity * i.i_wholesale_cost) AS total_wholesale_cost
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE i.i_current_price > 20
      AND t.t_hour BETWEEN 9 AND 21
      AND sr.sr_return_quantity > 0
    GROUP BY i.i_brand, t.t_hour
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    bh.i_brand,
    bh.t_hour,
    bh.num_returns,
    bh.total_return_amt,
    bh.total_net_loss,
    bh.avg_return_qty,
    bh.total_wholesale_cost,
    (bh.total_return_amt / NULLIF(bh.total_wholesale_cost, 0)) AS return_to_wholesale_ratio,
    RANK() OVER (PARTITION BY bh.t_hour ORDER BY bh.total_return_amt DESC) AS brand_rank_by_return_amt
FROM brand_hour_agg bh
ORDER BY bh.t_hour, brand_rank_by_return_amt
LIMIT 200
