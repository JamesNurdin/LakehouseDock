WITH cs_agg AS (
    SELECT
        cs_order_number,
        cs_item_sk,
        cs_warehouse_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS cs_cnt
    FROM catalog_sales
    WHERE cs_ship_mode_sk IN (3, 15)
      AND cs_ship_date_sk BETWEEN 2450837 AND 2450900
    GROUP BY cs_order_number, cs_item_sk, cs_warehouse_sk
)
SELECT
    s.s_store_id,
    w.w_warehouse_name,
    t.t_time,
    CASE
        WHEN cd.cd_gender = 'M' THEN 'Male'
        ELSE 'Female'
    END AS gender_category,
    cs_agg.total_net_paid,
    cr.cr_return_amount,
    ss.ss_ext_discount_amt,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cs_agg.total_net_paid DESC) AS rn_store_sales
FROM cs_agg
JOIN catalog_returns cr
    ON cr.cr_item_sk = cs_agg.cs_item_sk
   AND cr.cr_order_number = cs_agg.cs_order_number
JOIN warehouse w
    ON w.w_warehouse_sk = cs_agg.cs_warehouse_sk
JOIN time_dim t
    ON t.t_time_sk = cr.cr_returned_time_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
JOIN store_sales ss
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s
    ON s.s_store_sk = ss.ss_store_sk
JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE t.t_meal_time = 'lunch'
  AND t.t_shift = 'first'
  AND s.s_state = 'CA'
  AND inv.inv_quantity_on_hand > 100
  AND ss.ss_ext_discount_amt > 50
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_returned_time_sk = t.t_time_sk
          AND wr.wr_net_loss > 0
          AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    )
ORDER BY cs_agg.total_net_paid DESC
LIMIT 100
