WITH
  inventory_agg AS (
    SELECT
      inv_item_sk,
      inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_date_sk
  ),
  sales_pre AS (
    SELECT
      cs_item_sk,
      cs_sold_date_sk,
      cs_call_center_sk,
      cs_catalog_page_sk,
      cs_promo_sk,
      cs_bill_customer_sk,
      cs_order_number,
      SUM(cs_quantity) AS total_quantity,
      SUM(cs_ext_sales_price) AS total_sales,
      ARRAY[SUM(cs_quantity), SUM(cs_ext_sales_price)] AS metrics
    FROM catalog_sales
    WHERE cs_quantity > 0
      AND cs_ext_sales_price > 0
    GROUP BY
      cs_item_sk,
      cs_sold_date_sk,
      cs_call_center_sk,
      cs_catalog_page_sk,
      cs_promo_sk,
      cs_bill_customer_sk,
      cs_order_number
  )
SELECT
  d.d_year,
  cc.cc_state,
  i.i_category,
  i.i_class,
  cp.cp_type,
  p.p_promo_name,
  r.r_reason_desc,
  wp.wp_type,
  SUM(sp.total_quantity) AS sum_quantity,
  SUM(sp.total_sales) AS sum_sales,
  COUNT(DISTINCT sp.cs_item_sk) AS distinct_items_sold,
  MIN(sp.total_sales) AS min_sales,
  MAX(sp.total_sales) AS max_sales,
  ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(sp.total_sales) DESC) AS rn,
  metric
FROM sales_pre sp
JOIN date_dim d ON sp.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON sp.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i ON sp.cs_item_sk = i.i_item_sk
JOIN catalog_page cp ON sp.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON sp.cs_promo_sk = p.p_promo_sk
JOIN customer c ON sp.cs_bill_customer_sk = c.c_customer_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
JOIN catalog_returns cr ON cr.cr_order_number = sp.cs_order_number
  AND cr.cr_item_sk = sp.cs_item_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN inventory_agg inv ON inv.inv_item_sk = sp.cs_item_sk
  AND inv.inv_date_sk = sp.cs_sold_date_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
CROSS JOIN UNNEST(sp.metrics) AS t(metric)
WHERE d.d_year = 2001
  AND cc.cc_state = 'CA'
  AND i.i_category = 'Sports'
  AND cp.cp_type = 'monthly'
  AND p.p_discount_active = 'Y'
  AND r.r_reason_desc LIKE '%defect%'
GROUP BY
  d.d_year,
  cc.cc_state,
  i.i_category,
  i.i_class,
  cp.cp_type,
  p.p_promo_name,
  r.r_reason_desc,
  wp.wp_type,
  metric
ORDER BY sum_sales DESC
LIMIT 100
