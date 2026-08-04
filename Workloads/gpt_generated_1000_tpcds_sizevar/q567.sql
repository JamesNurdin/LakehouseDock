WITH sales_orders AS (
    SELECT cs.cs_order_number,
           cs.cs_item_sk,
           cs.cs_net_paid_inc_ship,
           cs.cs_coupon_amt,
           cs.cs_warehouse_sk,
           cs.cs_bill_hdemo_sk
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_ship > 1000
      AND cs.cs_coupon_amt > 100
),
orders_with_returns AS (
    SELECT so.cs_order_number
    FROM sales_orders so
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = so.cs_order_number
          AND cr.cr_item_sk = so.cs_item_sk
    )
),
orders_without_returns AS (
    SELECT cs_order_number FROM sales_orders
    EXCEPT
    SELECT cs_order_number FROM orders_with_returns
)
SELECT *
FROM (
    SELECT so.cs_order_number,
           so.cs_item_sk,
           w.w_warehouse_name,
           hd.hd_vehicle_count,
           ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY so.cs_net_paid_inc_ship DESC) AS sales_rank,
           (
               SELECT AVG(cr2.cr_return_amount)
               FROM catalog_returns cr2
               WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
           ) AS avg_return_amount
    FROM sales_orders so
    JOIN warehouse w ON so.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON so.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = so.cs_order_number AND cr.cr_item_sk = so.cs_item_sk
    WHERE so.cs_order_number IN (SELECT cs_order_number FROM orders_without_returns)
      AND hd.hd_vehicle_count >= 1
      AND ib.ib_upper_bound <= 100000
      AND w.w_state = 'CA'
    UNION
    SELECT cr.cr_order_number,
           cr.cr_item_sk,
           w2.w_warehouse_name,
           hd2.hd_vehicle_count,
           ROW_NUMBER() OVER (PARTITION BY w2.w_warehouse_id ORDER BY cr.cr_return_amount DESC) AS sales_rank,
           NULL AS avg_return_amount
    FROM catalog_returns cr
    JOIN warehouse w2 ON cr.cr_warehouse_sk = w2.w_warehouse_sk
    JOIN household_demographics hd2 ON cr.cr_refunded_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    WHERE cr.cr_return_amount > 0
      AND cr.cr_fee > 0
      AND hd2.hd_vehicle_count >= 0
      AND ib2.ib_lower_bound >= 20000
      AND w2.w_state = 'TX'
) combined
ORDER BY sales_rank ASC
LIMIT 100
