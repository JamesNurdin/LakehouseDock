WITH
  union_sales AS (
    SELECT
      i.i_item_sk,
      i.i_category,
      ss.ss_ext_sales_price      AS sales_amount,
      CASE WHEN ss.ss_ext_sales_price > 500 THEN 'High' ELSE 'Low' END AS sales_level
    FROM item i
    RIGHT OUTER JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_ext_tax > 100
    UNION
    SELECT
      i.i_item_sk,
      i.i_category,
      cs.cs_ext_sales_price      AS sales_amount,
      CASE WHEN cs.cs_ext_sales_price > 500 THEN 'High' ELSE 'Low' END AS sales_level
    FROM item i
    JOIN (SELECT * FROM catalog_sales TABLESAMPLE BERNOULLI (10)) cs
      ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_ext_tax > 100
  ),
  agg_sales AS (
    SELECT
      i_item_sk,
      i_category,
      sales_level,
      COUNT(*)                     AS txn_count,
      SUM(sales_amount)            AS total_sales,
      AVG(sales_amount)            AS avg_sales
    FROM union_sales
    GROUP BY i_item_sk, i_category, sales_level
  ),
  cs_sample AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (5)
  ),
  cs_with_cc AS (
    -- RIGHT OUTER JOIN keeps all call_center rows
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_call_center_sk,
      cs.cs_ship_mode_sk,
      cs.cs_sold_date_sk,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_ext_tax,
      cs.cs_bill_cdemo_sk,
      cs.cs_bill_addr_sk,
      cc.cc_call_center_id,
      cc.cc_name,
      cc.cc_state,
      cd.cd_credit_rating
    FROM cs_sample cs
    RIGHT OUTER JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  ),
  full_sales_returns AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_ship_mode_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount
    FROM cs_sample cs
    FULL OUTER JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
  )
SELECT
  a.i_category,
  a.sales_level,
  a.txn_count,
  a.total_sales,
  a.avg_sales,
  inv.inv_quantity_on_hand,
  cc.cc_name,
  sm.sm_carrier,
  cd.cd_credit_rating,
  CASE
    WHEN a.total_sales > 10000 THEN 'Top Category'
    ELSE 'Other Category'
  END AS category_rank
FROM agg_sales a
LEFT JOIN inventory inv
  ON inv.inv_item_sk = a.i_item_sk
LEFT JOIN cs_with_cc cc
  ON cc.cs_item_sk = a.i_item_sk
LEFT JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = cc.cs_ship_mode_sk
LEFT JOIN customer_demographics cd
  ON cd.cd_demo_sk = cc.cs_bill_cdemo_sk
WHERE inv.inv_quantity_on_hand IS NOT NULL
  AND inv.inv_quantity_on_hand > 500
  AND cc.cc_state = 'TX'
  AND sm.sm_carrier = 'DHL'
  AND cd.cd_credit_rating = 'Good'
  AND EXISTS (
        SELECT 1
        FROM customer_address ca
        WHERE ca.ca_state = cc.cc_state
          AND ca.ca_country = 'United States'
          AND ca.ca_zip LIKE '75%'
      )
ORDER BY a.total_sales DESC
LIMIT 50
