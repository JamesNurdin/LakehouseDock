/* goal: Compare average net loss and return counts per item category for 2021 between returns linked to returning household demographics versus refunded household demographics. */
WITH returning_hhdemo AS (
    SELECT
        d.d_year,
        i.i_category,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        COUNT(*) AS return_cnt,
        'returning_hhdemo' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2021
      AND hd.hd_vehicle_count >= 2
    GROUP BY d.d_year, i.i_category
),
refunded_hhdemo AS (
    SELECT
        d.d_year,
        i.i_category,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        COUNT(*) AS return_cnt,
        'refunded_hhdemo' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
        AND p.p_start_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2021
      AND hd.hd_income_band_sk = 3
    GROUP BY d.d_year, i.i_category
)
SELECT *
FROM returning_hhdemo
UNION ALL
SELECT *
FROM refunded_hhdemo
LIMIT 100
