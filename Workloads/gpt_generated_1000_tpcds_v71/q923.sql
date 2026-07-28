WITH returns AS (
    SELECT
        cc.cc_call_center_id AS call_center_id,
        ib.ib_lower_bound   AS income_lower,
        ib.ib_upper_bound   AS income_upper,
        SUM(cr.cr_net_loss) AS metric_value,
        'return_loss'       AS metric_type,
        COUNT(*)            AS row_cnt
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
      ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND ib.ib_upper_bound >= 50000
      AND td.t_sub_shift IN (
          SELECT DISTINCT t_sub_shift
          FROM time_dim
          WHERE t_hour BETWEEN 12 AND 13
      )
    GROUP BY cc.cc_call_center_id, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING SUM(cr.cr_net_loss) > 10000
),
sales AS (
    SELECT
        CAST(NULL AS varchar)       AS call_center_id,
        ib.ib_lower_bound            AS income_lower,
        ib.ib_upper_bound            AS income_upper,
        SUM(ss.ss_net_profit)        AS metric_value,
        'sales_profit'               AS metric_type,
        COUNT(*)                     AS row_cnt
    FROM store_sales ss
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND ib.ib_upper_bound >= 50000
      AND ss.ss_net_profit > (
          SELECT AVG(ss2.ss_net_profit)
          FROM store_sales ss2
      )
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_item_sk = ss.ss_item_sk
            AND cr2.cr_returned_date_sk = ss.ss_sold_date_sk
            AND cr2.cr_returned_time_sk = ss.ss_sold_time_sk
      )
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT *
FROM returns
UNION ALL
SELECT *
FROM sales
ORDER BY income_lower ASC, metric_type ASC, metric_value DESC
LIMIT 100
