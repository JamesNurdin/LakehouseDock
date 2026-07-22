SELECT channel, item_category, total_net_loss
FROM (
    SELECT 'store' AS channel,
           i.i_category AS item_category,
           SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2000
      AND ib.ib_lower_bound >= 70001
    GROUP BY i.i_category
    UNION ALL
    SELECT 'web' AS channel,
           i.i_category AS item_category,
           SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2000
      AND ib.ib_lower_bound >= 70001
    GROUP BY i.i_category
) combined
ORDER BY total_net_loss DESC
LIMIT 100
