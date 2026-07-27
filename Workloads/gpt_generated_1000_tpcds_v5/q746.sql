WITH filtered_wr AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_time_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 1
      AND wr.wr_return_amt > 10.00
      AND wr.wr_net_loss > 0
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND EXISTS (
            SELECT 1
            FROM time_dim td
            WHERE td.t_time_sk = wr.wr_returned_time_sk
              AND td.t_hour BETWEEN 8 AND 17
              AND td.t_minute BETWEEN 0 AND 30
              AND td.t_second IN (5, 16, 6)
          )
),
joined AS (
    SELECT
        i.i_category,
        i.i_brand,
        i.i_size,
        td.t_hour,
        fr.wr_return_quantity,
        fr.wr_return_amt,
        fr.wr_net_loss
    FROM filtered_wr fr
    JOIN item i ON fr.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON fr.wr_returned_time_sk = td.t_time_sk
    WHERE i.i_category = 'Electronics'
      AND i.i_wholesale_cost > 5.00
      AND i.i_brand_id IN (1, 2, 3)
      AND i.i_size = 'M'
)
SELECT
    i_category,
    i_brand,
    t_hour,
    SUM(wr_return_quantity) AS total_qty,
    SUM(wr_return_amt) AS total_return_amt,
    AVG(wr_net_loss) AS avg_net_loss,
    RANK() OVER (PARTITION BY i_category ORDER BY SUM(wr_return_quantity) DESC) AS qty_rank,
    CASE
        WHEN SUM(wr_return_amt) > 1000 THEN 'High'
        WHEN SUM(wr_return_amt) BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS return_level
FROM joined
GROUP BY i_category, i_brand, i_size, t_hour
ORDER BY total_qty DESC
LIMIT 100
