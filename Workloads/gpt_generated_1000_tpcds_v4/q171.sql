WITH catalog_part AS (
    SELECT
        i.i_item_id,
        w.w_city,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE i.i_category = 'Sports'
      AND w.w_city = 'Fairview'
      AND cs.cs_ext_sales_price > 1000
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_item_sk = cs.cs_item_sk
            AND ws.ws_ext_sales_price > 2000
      )
    GROUP BY i.i_item_id, w.w_city
),
web_part AS (
    SELECT
        i.i_item_id,
        w.w_city,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE i.i_class = 'Electronics'
      AND w.w_city = 'Fairview'
      AND ws.ws_ext_sales_price > 500
      AND i.i_item_id IN (
          SELECT DISTINCT i2.i_item_id
          FROM item i2
          WHERE i2.i_brand = 'Brand#23'
      )
    GROUP BY i.i_item_id, w.w_city
)
SELECT DISTINCT
    combined.i_item_id,
    combined.w_city,
    combined.total_sales,
    combined.order_cnt
FROM (
    SELECT i_item_id, w_city, total_sales, order_cnt FROM catalog_part
    UNION ALL
    SELECT i_item_id, w_city, total_sales, order_cnt FROM web_part
) AS combined
ORDER BY combined.total_sales DESC
LIMIT 100
