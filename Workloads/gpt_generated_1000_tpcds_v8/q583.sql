WITH
  call_center_hours AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      split(cc.cc_hours, '-') AS hour_parts,
      cc.cc_tax_percentage,
      cc.cc_gmt_offset
    FROM tpcds.call_center cc
    WHERE cc.cc_tax_percentage > 0.02
  ),
  exploded_hours AS (
    SELECT
      ch.cc_call_center_sk,
      ch.cc_name,
      TRIM(hour_part) AS hour_part,
      ch.cc_tax_percentage,
      ch.cc_gmt_offset
    FROM call_center_hours ch
    CROSS JOIN UNNEST(ch.hour_parts) AS t(hour_part)
  ),
  call_center_set_a AS (
    SELECT DISTINCT cc_call_center_sk
    FROM exploded_hours
    WHERE hour_part LIKE '8AM%'
  ),
  call_center_set_b AS (
    SELECT DISTINCT cs.cs_call_center_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    WHERE cs.cs_ext_sales_price > 2000
  ),
  intersect_ab AS (
    SELECT cc_call_center_sk FROM call_center_set_a
    INTERSECT
    SELECT cs_call_center_sk FROM call_center_set_b
  ),
  call_center_exclude_c AS (
    SELECT cc_call_center_sk
    FROM tpcds.call_center
    WHERE cc_gmt_offset < 0
  ),
  final_call_center_ids AS (
    SELECT cc_call_center_sk FROM intersect_ab
    EXCEPT
    SELECT cc_call_center_sk FROM call_center_exclude_c
  ),
  call_center_detail AS (
    SELECT
      'CALL_CENTER' AS entity_type,
      cc.cc_call_center_sk AS id,
      cc.cc_name AS name,
      CASE
        WHEN cc.cc_tax_percentage > 0.05 THEN 'HIGH_TAX'
        WHEN cc.cc_tax_percentage > 0.03 THEN 'MED_TAX'
        ELSE 'LOW_TAX'
      END AS category,
      (
        SELECT SUM(cs.cs_ext_sales_price)
        FROM tpcds.catalog_sales cs
        WHERE cs.cs_call_center_sk = cc.cc_call_center_sk
      ) AS total_sales
    FROM tpcds.call_center cc
    WHERE cc.cc_call_center_sk IN (SELECT cc_call_center_sk FROM final_call_center_ids)
  ),
  store_sales_detail AS (
    SELECT
      'STORE' AS entity_type,
      s.s_store_sk AS id,
      s.s_store_name AS name,
      CASE
        WHEN ss.ss_net_paid > 5000 THEN 'HIGH'
        ELSE 'LOW'
      END AS category,
      ss.ss_net_paid
    FROM tpcds.store_sales ss
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_net_paid > 0
      AND EXISTS (
        SELECT 1
        FROM tpcds.catalog_sales cs
        WHERE cs.cs_bill_customer_sk = ss.ss_customer_sk
          AND cs.cs_net_profit > 500
      )
  )
SELECT *
FROM (
  SELECT entity_type, id, name, category, total_sales AS metric
  FROM call_center_detail
  UNION ALL
  SELECT entity_type, id, name, category, ss_net_paid AS metric
  FROM store_sales_detail
) combined
ORDER BY metric DESC
LIMIT 100
