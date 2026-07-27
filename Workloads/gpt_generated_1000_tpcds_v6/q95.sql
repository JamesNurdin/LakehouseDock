WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_list_price,
        cs.cs_quantity
    FROM catalog_sales cs
    WHERE cs.cs_ext_list_price > 5000
      AND cs.cs_quantity >= 1
),
returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_ship_mode_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_net_loss IS NOT NULL
)
SELECT
    sm.sm_type,
    cd.cd_gender,
    CASE WHEN cr.cr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cs.cs_net_paid) AS avg_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS orders_count,
    MIN(cs.cs_ext_list_price) AS min_list_price,
    MAX(cs.cs_ext_list_price) AS max_list_price
FROM returns cr
JOIN sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_sales
    ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
    ON cs.cs_sold_time_sk = t_sales.t_time_sk
WHERE d_ret.d_fy_year = 1911
  AND t_ret.t_meal_time = 'dinner'
  AND sm.sm_type = 'AIR'
  AND cd.cd_gender = 'M'
  AND d_sales.d_fy_year = 1911
  AND t_sales.t_hour BETWEEN 12 AND 14
GROUP BY sm.sm_type,
         cd.cd_gender,
         CASE WHEN cr.cr_net_loss > 1000 THEN 'High' ELSE 'Low' END
ORDER BY total_net_loss DESC
LIMIT 100
