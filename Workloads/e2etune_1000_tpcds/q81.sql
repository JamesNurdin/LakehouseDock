WITH latest_year AS (
    SELECT MAX(d_year) AS max_year
    FROM date_dim
),
store_data AS (
    SELECT d.d_quarter_name,
           hd.hd_income_band_sk,
           'store' AS source,
           SUM(sr.sr_net_loss) AS net_loss,
           COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN latest_year ly ON d.d_year = ly.max_year
    GROUP BY d.d_quarter_name, hd.hd_income_band_sk
),
web_data AS (
    SELECT d.d_quarter_name,
           hd.hd_income_band_sk,
           'web' AS source,
           SUM(wr.wr_net_loss) AS net_loss,
           COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN latest_year ly ON d.d_year = ly.max_year
    GROUP BY d.d_quarter_name, hd.hd_income_band_sk
),
combined AS (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
),
aggregated AS (
    SELECT d_quarter_name,
           hd_income_band_sk,
           SUM(CASE WHEN source = 'store' THEN net_loss ELSE 0 END) AS store_net_loss,
           SUM(CASE WHEN source = 'web' THEN net_loss ELSE 0 END) AS web_net_loss,
           SUM(net_loss) AS total_net_loss,
           ROUND(100.0 * SUM(CASE WHEN source = 'store' THEN net_loss ELSE 0 END) / NULLIF(SUM(net_loss), 0), 2) AS store_loss_pct,
           ROUND(100.0 * SUM(CASE WHEN source = 'web' THEN net_loss ELSE 0 END) / NULLIF(SUM(net_loss), 0), 2) AS web_loss_pct
    FROM combined
    GROUP BY d_quarter_name, hd_income_band_sk
    HAVING SUM(net_loss) > 0
)
SELECT d_quarter_name,
       hd_income_band_sk,
       store_net_loss,
       web_net_loss,
       total_net_loss,
       store_loss_pct,
       web_loss_pct,
       RANK() OVER (PARTITION BY d_quarter_name ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY d_quarter_name, loss_rank
