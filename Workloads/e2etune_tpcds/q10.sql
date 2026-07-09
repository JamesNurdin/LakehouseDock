WITH agg AS (
    SELECT
        i.i_category AS category,
        i.i_brand AS brand,
        cd.cd_gender AS gender,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND hd.hd_vehicle_count >= 2
      AND wr.wr_return_amt_inc_tax > 100
    GROUP BY i.i_category, i.i_brand, cd.cd_gender
)
SELECT
    category,
    brand,
    gender,
    return_cnt,
    total_return_qty,
    avg_net_loss,
    total_return_amt_inc_tax,
    RANK() OVER (ORDER BY avg_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY net_loss_rank
LIMIT 100
