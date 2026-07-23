WITH ws_agg AS (
    SELECT
        ws_sold_time_sk,
        SUM(ws_net_paid_inc_tax) AS total_ws_net_paid_inc_tax,
        SUM(ws_coupon_amt) AS total_ws_coupon_amt,
        COUNT(*) AS ws_sales_cnt
    FROM web_sales
    WHERE ws_coupon_amt > 100.00
      AND ws_net_paid_inc_tax BETWEEN 500 AND 3000
    GROUP BY ws_sold_time_sk
),
cr_agg AS (
    SELECT
        cr_returned_time_sk,
        cr_returning_cdemo_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(cr_fee) AS total_fee
    FROM catalog_returns
    WHERE cr_fee > 10.00
      AND cr_return_quantity >= 1
      AND cr_return_amount > 0
    GROUP BY cr_returned_time_sk, cr_returning_cdemo_sk
)
SELECT
    td.t_time_sk,
    td.t_hour,
    td.t_second,
    cr_agg.cr_returning_cdemo_sk,
    cr_agg.total_return_amount,
    cr_agg.total_return_quantity,
    cr_agg.total_net_loss,
    cr_agg.total_fee,
    ws_agg.total_ws_net_paid_inc_tax,
    ws_agg.total_ws_coupon_amt,
    CASE
        WHEN cr_agg.total_net_loss > (SELECT AVG(cr_net_loss) FROM catalog_returns) THEN 'HIGH_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_category,
    RANK() OVER (PARTITION BY cr_agg.cr_returning_cdemo_sk ORDER BY cr_agg.total_net_loss DESC) AS net_loss_rank,
    ROW_NUMBER() OVER (ORDER BY cr_agg.total_return_amount DESC) AS overall_return_amount_rank
FROM cr_agg
JOIN time_dim td
    ON cr_agg.cr_returned_time_sk = td.t_time_sk
JOIN ws_agg
    ON ws_agg.ws_sold_time_sk = td.t_time_sk
WHERE td.t_hour BETWEEN 8 AND 20
  AND td.t_second > 5
  AND td.t_meal_time = 'Breakfast'
  AND td.t_shift = 'Day'
ORDER BY cr_agg.total_net_loss DESC
LIMIT 100
