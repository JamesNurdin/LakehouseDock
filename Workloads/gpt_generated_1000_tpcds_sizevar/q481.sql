WITH sampled_store_sales AS (
    SELECT ss.*
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
),
store_sales_agg AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        d.d_year
    FROM sampled_store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim WHERE d_year >= 2000)
      AND EXISTS (
          SELECT 1 FROM store s2
          WHERE s2.s_store_sk = ss.ss_store_sk
            AND s2.s_number_employees > 100
      )
    GROUP BY i.i_item_id, i.i_product_name, d.d_year
),
web_sales_agg AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        d.d_year
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim WHERE d_year >= 2000)
    GROUP BY i.i_item_id, i.i_product_name, d.d_year
),
combined AS (
    SELECT i_item_id, i_product_name, total_sales, d_year FROM store_sales_agg
    UNION ALL
    SELECT i_item_id, i_product_name, total_sales, d_year FROM web_sales_agg
),
returned_items AS (
    SELECT i.i_item_id
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim WHERE d_year >= 2000)
),
final_set AS (
    SELECT *
    FROM combined
    EXCEPT
    SELECT c.i_item_id, c.i_product_name, c.total_sales, c.d_year
    FROM combined c
    JOIN returned_items r ON c.i_item_id = r.i_item_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num,
    i_item_id,
    i_product_name,
    total_sales,
    d_year
FROM final_set
ORDER BY total_sales DESC
LIMIT 100
