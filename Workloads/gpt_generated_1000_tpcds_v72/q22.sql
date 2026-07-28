WITH sales_state AS (
    SELECT
        ca.ca_state AS state,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rn
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE i.i_category = 'Electronics'
      AND i.i_rec_start_date >= DATE '1999-01-01'
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
            AND wp.wp_type = 'home'
      )
      AND ws.ws_bill_customer_sk IN (
          SELECT ws2.ws_bill_customer_sk
          FROM web_sales ws2
          WHERE ws2.ws_sales_price > 50
          LIMIT 1
      )
    GROUP BY ca.ca_state, i.i_category
    HAVING SUM(ws.ws_ext_sales_price) > 10000
),
sports_sales AS (
    SELECT
        ca.ca_state AS state,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rn
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE i.i_category = 'Sports'
      AND i.i_rec_start_date >= DATE '2000-01-01'
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
            AND wp.wp_type = 'home'
      )
    GROUP BY ca.ca_state, i.i_category
    HAVING SUM(ws.ws_ext_sales_price) > 8000
)
SELECT state,
       category,
       total_sales,
       rn
FROM sales_state
UNION ALL
SELECT state,
       category,
       total_sales,
       rn
FROM sports_sales
ORDER BY total_sales DESC
LIMIT 100
