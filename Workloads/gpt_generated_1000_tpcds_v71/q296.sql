WITH recent_catalog_returns AS (
        SELECT cr.cr_item_sk,
               cr.cr_return_amount,
               cr.cr_return_quantity,
               cr.cr_returned_date_sk,
               cr.cr_warehouse_sk
        FROM catalog_returns cr
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        WHERE td.t_hour BETWEEN 9 AND 17
),
     recent_web_sales AS (
        SELECT ws.ws_item_sk,
               ws.ws_ext_sales_price,
               ws.ws_order_number,
               ws.ws_warehouse_sk
        FROM web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        WHERE td.t_hour BETWEEN 9 AND 17
     )
SELECT
        i.i_category                                            AS category,
        COUNT(DISTINCT r.cr_returned_date_sk)                  AS return_days,
        SUM(r.cr_return_amount)                                AS total_return_amount,
        CASE WHEN SUM(r.cr_return_amount) > 5000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
        CONCAT(i.i_brand, ' ', i.i_product_name)               AS full_product_name,
        (SELECT AVG(ws_ext_sales_price) FROM recent_web_sales) AS avg_sales_price
FROM recent_catalog_returns r
JOIN item i ON r.cr_item_sk = i.i_item_sk
JOIN warehouse w ON r.cr_warehouse_sk = w.w_warehouse_sk
WHERE regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
  AND w.w_city LIKE 'San%'
GROUP BY i.i_category, i.i_brand, i.i_product_name

UNION ALL

SELECT
        i2.i_category                                             AS category,
        COUNT(DISTINCT wr.wr_returned_date_sk)                    AS return_days,
        SUM(wr.wr_return_amt)                                    AS total_return_amount,
        CASE WHEN SUM(wr.wr_return_amt) > 3000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
        CONCAT(i2.i_brand, ' ', i2.i_product_name)               AS full_product_name,
        (SELECT AVG(ws_ext_sales_price) FROM recent_web_sales)  AS avg_sales_price
FROM web_returns wr
JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_url LIKE '%/return/%'
  AND regexp_like(i2.i_item_desc, '^.*[A-Z]{2}[0-9]{3}.*$')
  AND EXISTS (
        SELECT 1
        FROM customer_address ca
        WHERE ca.ca_address_sk = wr.wr_refunded_addr_sk
          AND ca.ca_city = 'Seattle'
    )
GROUP BY i2.i_category, i2.i_brand, i2.i_product_name

ORDER BY total_return_amount DESC
