WITH
  sample_items AS (
    SELECT i_item_sk, i_brand, i_manufact_id
    FROM item
    TABLESAMPLE BERNOULLI (10)
  ),
  sales_data AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_order_number,
      cs.cs_net_paid_inc_ship,
      cp.cp_department,
      sm.sm_ship_mode_id,
      ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY cs.cs_net_paid_inc_ship DESC) AS brand_rank
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_net_paid_inc_ship > 1000
  ),
  returns_data AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_return_amount,
      r.r_reason_desc
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 500
  ),
  intersect_keys AS (
    SELECT cs_item_sk AS item_sk FROM sales_data
    INTERSECT
    SELECT cr_item_sk AS item_sk FROM returns_data
  ),
  store_return_data AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_return_amt,
      r.r_reason_desc AS store_reason,
      ca.ca_state
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_amt > 300
  )
SELECT
  combined.item_sk,
  combined.cs_order_number,
  combined.cs_net_paid_inc_ship,
  combined.cp_department,
  combined.sm_ship_mode_id,
  combined.brand_rank,
  combined.catalog_return_reason
FROM (
  SELECT
    s.cs_item_sk AS item_sk,
    s.cs_order_number,
    s.cs_net_paid_inc_ship,
    s.cp_department,
    s.sm_ship_mode_id,
    s.brand_rank,
    r.r_reason_desc AS catalog_return_reason
  FROM sales_data s
  JOIN intersect_keys ik ON s.cs_item_sk = ik.item_sk
  JOIN returns_data r ON r.cr_item_sk = s.cs_item_sk
  WHERE EXISTS (
    SELECT 1
    FROM sample_items si
    WHERE si.i_item_sk = s.cs_item_sk
      AND si.i_manufact_id = 350
  )

  UNION ALL

  SELECT
    sr.sr_item_sk AS item_sk,
    NULL AS cs_order_number,
    NULL AS cs_net_paid_inc_ship,
    NULL AS cp_department,
    NULL AS sm_ship_mode_id,
    NULL AS brand_rank,
    sr.store_reason AS catalog_return_reason
  FROM store_return_data sr
  WHERE sr.ca_state = 'California'
) AS combined
ORDER BY combined.cs_net_paid_inc_ship DESC NULLS LAST
LIMIT 100
