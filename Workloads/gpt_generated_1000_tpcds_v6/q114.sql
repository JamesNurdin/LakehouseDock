WITH filtered_sales AS (
    SELECT
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ws.ws_ext_list_price,
        ws.ws_ship_customer_sk,
        i.i_category,
        i.i_brand,
        i.i_brand_id
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND i.i_brand_id = 2004002
      AND ws.ws_ext_list_price > 5000
      AND ws.ws_ext_tax < 100
      AND ws.ws_ship_customer_sk IN (
          SELECT ws2.ws_ship_customer_sk
          FROM web_sales ws2
          WHERE ws2.ws_ext_discount_amt > 1500
          LIMIT 1000
      )
),
agg AS (
    SELECT
        i_category,
        i_brand,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_tax) AS avg_tax,
        COUNT(*) AS order_cnt,
        MIN(ws_ext_list_price) AS min_list_price,
        MAX(ws_ext_list_price) AS max_list_price
    FROM filtered_sales
    GROUP BY i_category, i_brand
    HAVING SUM(ws_ext_sales_price) > 100000
)
SELECT
    i_category,
    i_brand,
    total_sales,
    avg_tax,
    order_cnt,
    min_list_price,
    max_list_price,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
    SUM(total_sales) OVER (PARTITION BY i_category ORDER BY total_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_by_category
FROM agg
ORDER BY total_sales DESC
LIMIT 100
