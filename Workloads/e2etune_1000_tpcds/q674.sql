WITH agg_returns AS (
    SELECT
        i.i_brand,
        i.i_category,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_quantity,
        SUM(wr.wr_fee) AS total_fees,
        MIN(wr.wr_returned_date_sk) AS earliest_return_date_sk,
        MAX(wr.wr_returned_date_sk) AS latest_return_date_sk
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2458000 AND 2459000
      AND i.i_brand IN ('BrandA', 'BrandB', 'BrandC')
    GROUP BY i.i_brand, i.i_category
    HAVING SUM(wr.wr_net_loss) > 10000
)
SELECT
    ar.i_brand,
    ar.i_category,
    ar.distinct_orders,
    ar.total_return_amount,
    ar.total_net_loss,
    ar.avg_return_quantity,
    ar.total_fees,
    ar.earliest_return_date_sk,
    ar.latest_return_date_sk,
    RANK() OVER (ORDER BY ar.total_net_loss DESC) AS net_loss_rank
FROM agg_returns ar
ORDER BY ar.total_net_loss DESC
LIMIT 50
