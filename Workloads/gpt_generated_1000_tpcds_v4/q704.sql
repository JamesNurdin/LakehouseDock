WITH filtered_returns AS (
    SELECT cr_returned_date_sk,
           cr_returned_time_sk,
           cr_item_sk,
           cr_refunded_cdemo_sk,
           cr_returning_cdemo_sk,
           cr_call_center_sk,
           cr_warehouse_sk,
           cr_return_amount,
           cr_return_quantity
    FROM catalog_returns
    WHERE cr_return_amount > 100.0
),
union_returns AS (
    SELECT cr_returned_date_sk,
           cr_returned_time_sk,
           cr_item_sk,
           cr_refunded_cdemo_sk,
           cr_returning_cdemo_sk,
           cr_call_center_sk,
           cr_warehouse_sk,
           cr_return_amount,
           cr_return_quantity
    FROM filtered_returns
    WHERE cr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_moy = 5
    )
    UNION ALL
    SELECT cr_returned_date_sk,
           cr_returned_time_sk,
           cr_item_sk,
           cr_refunded_cdemo_sk,
           cr_returning_cdemo_sk,
           cr_call_center_sk,
           cr_warehouse_sk,
           cr_return_amount,
           cr_return_quantity
    FROM filtered_returns
    WHERE cr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_moy = 9
    )
)
SELECT
    cc.cc_name                         AS call_center_name,
    w.w_city                           AS warehouse_city,
    d_ret.d_moy                        AS return_month,
    SUM(ur.cr_return_amount)          AS total_return_amount,
    COUNT(*)                           AS return_cnt,
    AVG(ur.cr_return_quantity)        AS avg_quantity,
    (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return_amount
FROM union_returns ur
JOIN call_center cc
  ON ur.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON ur.cr_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t
  ON ur.cr_returned_time_sk = t.t_time_sk
JOIN date_dim d_ret
  ON ur.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN customer_demographics cd_ref
  ON ur.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
  ON ur.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN web_page wp
  ON wp.wp_type = 'A'                               -- any predicate to keep the join valid
JOIN date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM customer_demographics cd_chk
    WHERE cd_chk.cd_demo_sk = ur.cr_returning_cdemo_sk
      AND cd_chk.cd_gender = 'F'
      AND cd_chk.cd_purchase_estimate > 5000
)
GROUP BY
    cc.cc_name,
    w.w_city,
    d_ret.d_moy
ORDER BY total_return_amount DESC
