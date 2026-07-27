WITH per_group AS (
    SELECT
        i.i_category AS category,
        cd.cd_credit_rating AS credit_rating,
        hd.hd_vehicle_count AS vehicle_count,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_fee) AS avg_fee,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE cd.cd_credit_rating IN ('Low Risk', 'High Risk')
      AND cd.cd_marital_status = 'M'
      AND i.i_current_price BETWEEN 10 AND 100
      AND i.i_brand IN ('BrandA', 'BrandB')
      AND hd.hd_vehicle_count >= 0
      AND hd.hd_dep_count BETWEEN 1 AND 8
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 20
    GROUP BY i.i_category, cd.cd_credit_rating, hd.hd_vehicle_count
    HAVING SUM(sr.sr_net_loss) > 1000
)
SELECT
    category,
    AVG(total_net_loss) AS avg_total_net_loss,
    SUM(return_cnt) AS total_returns,
    AVG(avg_fee) AS avg_fee_across_groups
FROM per_group
GROUP BY category
HAVING AVG(total_net_loss) > 2000
ORDER BY avg_total_net_loss DESC
LIMIT 100
