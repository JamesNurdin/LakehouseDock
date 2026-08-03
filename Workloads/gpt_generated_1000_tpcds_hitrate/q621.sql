WITH joined_data AS (
    SELECT
        cc.cc_name,
        cd.cd_education_status,
        i.i_category,
        i.i_current_price,
        c.c_customer_id,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        p.p_promo_name,
        inv.inv_quantity_on_hand,
        CASE WHEN i.i_current_price > 200 THEN 'Premium' ELSE 'Standard' END AS price_category
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
     AND ss.ss_customer_sk = c.c_customer_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = i.i_item_sk
     AND cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_class = 'large'
      AND cd.cd_marital_status = 'M'
      AND inv.inv_quantity_on_hand > 500
      AND i.i_current_price > 100
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cs.cs_order_number
            AND cr2.cr_return_quantity > 0
      )
),
aggregated AS (
    SELECT
        cc_name,
        cd_education_status,
        i_category,
        price_category,
        SUM(cs_net_paid) AS total_sales,
        AVG(cs_net_paid) AS avg_sales,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        MIN(cs_quantity) AS min_quantity,
        MAX(cs_quantity) AS max_quantity
    FROM joined_data
    GROUP BY cc_name, cd_education_status, i_category, price_category
)
SELECT
    cc_name,
    cd_education_status,
    i_category,
    price_category,
    total_sales,
    avg_sales,
    distinct_orders,
    distinct_customers,
    min_quantity,
    max_quantity,
    LAG(total_sales) OVER (PARTITION BY price_category ORDER BY total_sales DESC) AS lag_total_sales
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
