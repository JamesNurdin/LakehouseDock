WITH store_agg AS (
        SELECT
            ss_item_sk,
            SUM(ss_ext_sales_price) AS store_sales_total,
            SUM(ss_ext_discount_amt) AS store_discount_total,
            COUNT(*) AS store_txn_cnt
        FROM store_sales
        WHERE ss_coupon_amt > 100
          AND ss_wholesale_cost < 50
          AND ss_list_price BETWEEN 20 AND 150
          AND ss_quantity >= 1
          AND ss_ext_sales_price > 0
          AND ss_ext_tax < 20
        GROUP BY ss_item_sk
    ),
    web_agg AS (
        SELECT
            ws_item_sk,
            SUM(ws_ext_sales_price) AS web_sales_total,
            SUM(ws_ext_discount_amt) AS web_discount_total,
            COUNT(*) AS web_txn_cnt
        FROM web_sales
        WHERE ws_list_price > 50
          AND ws_ship_addr_sk IN (5307647, 2764947, 5335848)
          AND ws_ext_wholesale_cost > 500
          AND ws_coupon_amt < 200
          AND ws_quantity >= 1
          AND ws_ext_tax < 30
        GROUP BY ws_item_sk
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_manager_id,
    COALESCE(s.store_sales_total, 0) AS store_sales_total,
    COALESCE(w.web_sales_total, 0) AS web_sales_total,
    COALESCE(s.store_sales_total, 0) + COALESCE(w.web_sales_total, 0) AS total_sales,
    RANK() OVER (PARTITION BY i.i_brand ORDER BY COALESCE(s.store_sales_total, 0) + COALESCE(w.web_sales_total, 0) DESC) AS brand_sales_rank,
    CASE
        WHEN COALESCE(s.store_sales_total, 0) + COALESCE(w.web_sales_total, 0) > 100000 THEN 'High'
        WHEN COALESCE(s.store_sales_total, 0) + COALESCE(w.web_sales_total, 0) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM item i
LEFT JOIN store_agg s ON s.ss_item_sk = i.i_item_sk
LEFT JOIN web_agg w ON w.ws_item_sk = i.i_item_sk
WHERE i.i_manager_id IN (98, 40, 41, 34, 26)
  AND i.i_formulation LIKE '%goldenrod%'
  AND i.i_category = 'Sports'
ORDER BY total_sales DESC
LIMIT 100
