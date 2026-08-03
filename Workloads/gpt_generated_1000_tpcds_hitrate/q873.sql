WITH
  sales_data AS (
    SELECT
      i.i_category AS category,
      c.c_birth_country AS birth_country,
      SUM(cs.cs_net_paid) AS total_metric,
      COUNT(DISTINCT cs.cs_order_number) AS transaction_count,
      SUM(CASE WHEN p.p_discount_active = 'Y' THEN cs.cs_ext_discount_amt ELSE 0 END) AS special_amount,
      ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_net_paid) DESC) AS rn
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE c.c_birth_country = 'JAPAN'
      AND i.i_category = 'Electronics'
      AND w.w_warehouse_sq_ft > 600000
      AND p.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand > 0
    GROUP BY i.i_category, c.c_birth_country
    HAVING SUM(cs.cs_net_paid) > 10000
  ),
  returns_data AS (
    SELECT
      i.i_category AS category,
      c.c_birth_country AS birth_country,
      SUM(cr.cr_net_loss) AS total_metric,
      COUNT(DISTINCT cr.cr_order_number) AS transaction_count,
      SUM(CASE WHEN r.r_reason_desc = 'Damaged' THEN cr.cr_return_amount ELSE 0 END) AS special_amount,
      ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cr.cr_net_loss) DESC) AS rn
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE c.c_birth_country = 'JAPAN'
      AND i.i_category = 'Electronics'
      AND r.r_reason_desc IN ('Damaged','Defective')
      AND w.w_warehouse_sq_ft > 600000
      AND inv.inv_quantity_on_hand > 0
    GROUP BY i.i_category, c.c_birth_country
    HAVING SUM(cr.cr_net_loss) > 0

    UNION ALL

    SELECT
      i.i_category AS category,
      c.c_birth_country AS birth_country,
      SUM(wr.wr_net_loss) AS total_metric,
      COUNT(DISTINCT wr.wr_order_number) AS transaction_count,
      SUM(CASE WHEN r.r_reason_desc = 'Damaged' THEN wr.wr_return_amt ELSE 0 END) AS special_amount,
      ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(wr.wr_net_loss) DESC) AS rn
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE c.c_birth_country = 'JAPAN'
      AND i.i_category = 'Electronics'
      AND r.r_reason_desc IN ('Damaged','Defective')
      AND w.w_warehouse_sq_ft > 600000
      AND inv.inv_quantity_on_hand > 0
    GROUP BY i.i_category, c.c_birth_country
    HAVING SUM(wr.wr_net_loss) > 0
  )
SELECT
  category,
  birth_country,
  total_metric,
  transaction_count,
  special_amount
FROM sales_data
WHERE rn <= 5

UNION DISTINCT

SELECT
  category,
  birth_country,
  total_metric * -1 AS total_metric,
  transaction_count,
  special_amount
FROM returns_data
WHERE rn <= 5

ORDER BY total_metric DESC
LIMIT 100
