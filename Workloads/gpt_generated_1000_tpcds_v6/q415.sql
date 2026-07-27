WITH store_data AS (
    SELECT
        td.t_hour AS hour,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_fee > (SELECT AVG(sr2.sr_fee) FROM store_returns sr2)
      AND hd.hd_vehicle_count > 2
      AND td.t_hour BETWEEN 8 AND 12
    GROUP BY td.t_hour
),
web_data AS (
    SELECT
        td.t_hour AS hour,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'product'
      AND wr.wr_fee > 20
      AND hd.hd_dep_count >= 5
    GROUP BY td.t_hour
)
SELECT hour,
       total_net_loss,
       return_cnt,
       'store' AS source
FROM store_data
UNION ALL
SELECT hour,
       total_net_loss,
       return_cnt,
       'web' AS source
FROM web_data
ORDER BY hour,
         total_net_loss DESC
LIMIT 100
