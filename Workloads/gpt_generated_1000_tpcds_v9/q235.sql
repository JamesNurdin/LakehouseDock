-- Goal: Analyze catalog sales performance for scanner items shipped from a specific warehouse, compare with web‑sales metrics, and identify the top web‑sale amount per item‑warehouse pair.
WITH recent_scanners AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_rec_end_date
    FROM item i
    WHERE i.i_class = 'scanners'
      AND i.i_rec_end_date > DATE '2000-01-01'
),
web_sales_summary AS (
    SELECT
        ws.ws_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        AVG(ws.ws_sales_price) AS web_avg_price
    FROM web_sales ws
    JOIN recent_scanners rs ON ws.ws_item_sk = rs.i_item_sk
    WHERE ws.ws_list_price > 60
      AND ws.ws_ext_ship_cost > 1000
    GROUP BY ws.ws_item_sk
)
SELECT
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    w.w_warehouse_name,
    i.i_product_name,
    i.i_brand,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    ws_sum.web_sales_total,
    ws_sum.web_order_cnt,
    top_ws.max_ws_ext_sales_price
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN recent_scanners i
    ON cs.cs_item_sk = i.i_item_sk
JOIN web_sales_summary ws_sum
    ON ws_sum.ws_item_sk = i.i_item_sk
CROSS JOIN LATERAL (
    SELECT ws.ws_ext_sales_price AS max_ws_ext_sales_price
    FROM web_sales ws
    WHERE ws.ws_item_sk = i.i_item_sk
      AND ws.ws_warehouse_sk = w.w_warehouse_sk
      AND ws.ws_list_price > 80
    ORDER BY ws.ws_ext_sales_price DESC
    LIMIT 1
) AS top_ws
WHERE w.w_zip = '35709'
  AND EXISTS (
      SELECT 1
      FROM web_sales ws_ex
      WHERE ws_ex.ws_item_sk = i.i_item_sk
        AND ws_ex.ws_ext_ship_cost > 1200
  )
GROUP BY
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    w.w_warehouse_name,
    i.i_product_name,
    i.i_brand,
    ws_sum.web_sales_total,
    ws_sum.web_order_cnt,
    top_ws.max_ws_ext_sales_price
HAVING
    SUM(cs.cs_ext_sales_price) > 5000
    AND COUNT(DISTINCT cs.cs_order_number) > 5
ORDER BY catalog_sales_total DESC
LIMIT 100
