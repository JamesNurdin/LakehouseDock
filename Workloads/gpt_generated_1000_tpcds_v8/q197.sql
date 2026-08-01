WITH
  warehouse_inventory AS (
    SELECT
      w.w_warehouse_sk,
      w.w_warehouse_name,
      inv_sum.total_qty
    FROM warehouse w
    LEFT JOIN LATERAL (
      SELECT SUM(i.inv_quantity_on_hand) AS total_qty
      FROM inventory i
      WHERE i.inv_warehouse_sk = w.w_warehouse_sk
    ) inv_sum ON TRUE
  ),
  sales_union AS (
    SELECT
      cs.cs_sold_date_sk          AS sold_date_sk,
      cs.cs_warehouse_sk          AS warehouse_sk,
      cs.cs_item_sk               AS item_sk,
      cs.cs_ext_sales_price       AS sales_amount,
      'catalog'                   AS sales_source,
      cs.cs_quantity              AS quantity,
      cp.cp_catalog_page_number   AS catalog_page_number,
      cp.cp_department            AS department,
      CAST(NULL AS varchar)       AS web_page_id
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_wholesale_cost > 70
      AND cp.cp_catalog_page_number IN (5, 8)
    UNION ALL
    SELECT
      ws.ws_sold_date_sk          AS sold_date_sk,
      ws.ws_warehouse_sk          AS warehouse_sk,
      ws.ws_item_sk               AS item_sk,
      ws.ws_ext_sales_price       AS sales_amount,
      'web'                       AS sales_source,
      ws.ws_quantity              AS quantity,
      CAST(NULL AS integer)       AS catalog_page_number,
      CAST(NULL AS varchar)       AS department,
      wp.wp_web_page_id           AS web_page_id
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_wholesale_cost > 70
      AND wp.wp_image_count >= 5
  )
SELECT
  wi.w_warehouse_name,
  wi.total_qty,
  su.sales_source,
  su.sales_amount,
  su.quantity,
  COALESCE(su.catalog_page_number, -1)    AS catalog_page_number,
  COALESCE(su.department, 'N/A')          AS department,
  su.web_page_id,
  RANK() OVER (PARTITION BY su.warehouse_sk ORDER BY su.sales_amount DESC) AS sales_rank,
  (
    SELECT COUNT(*)
    FROM sales_union su2
    WHERE su2.warehouse_sk = su.warehouse_sk
      AND su2.sales_amount > su.sales_amount
  ) + 1 AS alternate_rank
FROM sales_union su
JOIN warehouse_inventory wi ON su.warehouse_sk = wi.w_warehouse_sk
WHERE EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = su.warehouse_sk
          AND cs2.cs_ext_sales_price > 5000
      )
  AND su.sales_amount > (
        SELECT AVG(cs_ext_sales_price)
        FROM catalog_sales
        WHERE cs_warehouse_sk = su.warehouse_sk
      )
ORDER BY wi.w_warehouse_name, sales_rank
LIMIT 100
