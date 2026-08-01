WITH refunded AS (
   SELECT
       cd.cd_gender AS gender,
       hd.hd_vehicle_count AS vehicle_count,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
       CASE
           WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High'
           WHEN SUM(cr.cr_net_loss) > 0 THEN 'Medium'
           ELSE 'Low'
       END AS loss_category
   FROM catalog_returns cr
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE cr.cr_refunded_cash > 100
   GROUP BY cd.cd_gender, hd.hd_vehicle_count
),
returning AS (
   SELECT
       cd.cd_gender AS gender,
       hd.hd_vehicle_count AS vehicle_count,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
       CASE
           WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High'
           WHEN SUM(cr.cr_net_loss) > 0 THEN 'Medium'
           ELSE 'Low'
       END AS loss_category
   FROM catalog_returns cr
   JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
   WHERE cr.cr_store_credit > 200
   GROUP BY cd.cd_gender, hd.hd_vehicle_count
),
unioned AS (
   SELECT gender, vehicle_count, total_return_amount, distinct_orders, loss_category FROM refunded
   UNION ALL
   SELECT gender, vehicle_count, total_return_amount, distinct_orders, loss_category FROM returning
)
SELECT
    u1.gender,
    u1.vehicle_count,
    u1.loss_category,
    u1.total_return_amount,
    u1.distinct_orders,
    (SELECT SUM(u2.total_return_amount)
     FROM unioned u2
     WHERE u2.loss_category = u1.loss_category) AS category_total_return_amount
FROM unioned u1
ORDER BY u1.total_return_amount DESC
LIMIT 100
