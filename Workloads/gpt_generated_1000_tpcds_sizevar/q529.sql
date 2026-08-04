WITH
  sales_cc AS (
    SELECT DISTINCT cc.cc_call_center_id
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cp.cp_catalog_number BETWEEN 10 AND 20
      AND cs.cs_quantity > 5
      AND cs.cs_sales_price > 100
      AND EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_page_sk = cs.cs_catalog_page_sk
          AND cp2.cp_type = 'PROMO'
      )
  ),
  returns_cc AS (
    SELECT DISTINCT cc.cc_call_center_id
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cp.cp_catalog_number BETWEEN 10 AND 20
      AND cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 50
  ),
  union_cc AS (
    SELECT cc_call_center_id FROM sales_cc
    UNION
    SELECT cc_call_center_id FROM returns_cc
  ),
  cc_warehouse AS (
    SELECT DISTINCT cc.cc_call_center_id, w.w_warehouse_name
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  ),
  full_join AS (
    SELECT
      COALESCE(u.cc_call_center_id, w.cc_call_center_id) AS cc_call_center_id,
      u.cc_call_center_id AS in_union,
      w.w_warehouse_name
    FROM union_cc u
    FULL OUTER JOIN cc_warehouse w
      ON u.cc_call_center_id = w.cc_call_center_id
  ),
  intersect_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    WHERE cs.cs_sales_price > 200
    INTERSECT
    SELECT ws.ws_order_number AS order_number
    FROM web_sales ws
    WHERE ws.ws_sales_price > 200
  ),
  except_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    EXCEPT
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
  )
SELECT
  fj.cc_call_center_id AS entity_id,
  'FullJoin' AS source
FROM full_join fj
UNION
SELECT
  CAST(io.order_number AS varchar) AS entity_id,
  'IntersectOrders' AS source
FROM intersect_orders io
UNION
SELECT
  CAST(eo.order_number AS varchar) AS entity_id,
  'SalesExceptReturns' AS source
FROM except_orders eo
ORDER BY entity_id
