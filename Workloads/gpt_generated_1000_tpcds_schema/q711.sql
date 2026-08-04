WITH
  sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  sales_with_item AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_promo_sk,
      i.i_category,
      p.p_discount_active,
      cc.cc_division_name,
      sm.sm_type
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  ),
  returns_with_item AS (
    SELECT
      cr.cr_order_number,
      cr.cr_item_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      i2.i_category AS return_category,
      r.r_reason_desc,
      cc2.cc_division_name AS return_division,
      sm2.sm_type AS return_ship_type
    FROM catalog_returns cr
    JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc2 ON cr.cr_call_center_sk = cc2.cc_call_center_sk
    JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
  ),
  web_activity AS (
    SELECT
      wr.wr_order_number,
      wr.wr_item_sk,
      wp.wp_type,
      r2.r_reason_desc AS web_reason,
      CASE WHEN wr.wr_return_amt > 100 THEN 'HIGH' ELSE 'LOW' END AS return_level
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    JOIN item i3 ON wr.wr_item_sk = i3.i_item_sk
  )
SELECT
  COALESCE(s.cs_order_number, r.cr_order_number) AS order_number,
  s.i_category,
  r.return_category,
  SUM(CASE WHEN s.cs_quantity > 0 THEN s.cs_net_paid ELSE 0 END) AS total_sales,
  SUM(CASE WHEN r.cr_return_quantity > 0 THEN r.cr_return_amount ELSE 0 END) AS total_returns,
  COUNT(DISTINCT CASE WHEN s.cs_quantity > 0 THEN s.cs_order_number END) AS sales_orders,
  COUNT(DISTINCT CASE WHEN r.cr_return_quantity > 0 THEN r.cr_order_number END) AS return_orders,
  MAX(wa.return_level) AS highest_return_level
FROM sales_with_item s
FULL OUTER JOIN returns_with_item r
  ON s.cs_order_number = r.cr_order_number
  AND s.cs_item_sk = r.cr_item_sk
LEFT JOIN sampled_inventory inv
  ON s.cs_item_sk = inv.inv_item_sk
LEFT JOIN web_activity wa
  ON COALESCE(s.cs_order_number, r.cr_order_number) = wa.wr_order_number
WHERE EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = s.cs_promo_sk
          AND p.p_discount_active = 'Y'
      )
  AND s.i_category IN (
        SELECT i_cat.i_category
        FROM item i_cat
        WHERE i_cat.i_brand = 'Brand#12'
      )
  AND COALESCE(s.cs_order_number, r.cr_order_number) IN (
        SELECT order_number
        FROM (
              SELECT cs_order_number AS order_number FROM catalog_sales
              INTERSECT
              SELECT wr_order_number FROM web_returns
            ) intersected
      )
GROUP BY
  COALESCE(s.cs_order_number, r.cr_order_number),
  s.i_category,
  r.return_category
HAVING SUM(CASE WHEN s.cs_quantity > 0 THEN s.cs_net_paid ELSE 0 END) > 0
ORDER BY total_sales DESC
LIMIT 100
