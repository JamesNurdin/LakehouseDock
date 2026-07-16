SELECT
    i_category,
    i_brand,
    return_cnt,
    total_net_loss,
    avg_return_amt,
    total_return_qty,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM (
    SELECT
        i.i_category,
        i.i_brand,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN item i
      ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ret
      ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret
      ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    WHERE cd_ret.cd_gender = 'F'
      AND cd_ret.cd_credit_rating = 'Good'
      AND hd_ret.hd_vehicle_count >= 2
      AND hd_ret.hd_buy_potential = 'High'
      AND wr.wr_returned_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY i.i_category, i.i_brand
    HAVING SUM(wr.wr_net_loss) > 0
) t
ORDER BY total_net_loss DESC
LIMIT 10
