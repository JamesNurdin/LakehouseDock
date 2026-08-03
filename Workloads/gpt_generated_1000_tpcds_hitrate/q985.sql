WITH
  item_attrs AS (
    SELECT i_item_sk,
           ARRAY[CAST(i_category AS varchar), CAST(i_brand AS varchar)] AS attr_array
    FROM item
  ),
  ss_agg AS (
    SELECT ss_item_sk,
           ss_customer_sk,
           SUM(ss_ext_sales_price) AS total_sales,
           SUM(ss_quantity) AS total_qty
    FROM store_sales
    WHERE ss_ext_sales_price > 1000
    GROUP BY ss_item_sk, ss_customer_sk
  ),
  cr_agg AS (
    SELECT cr_item_sk,
           SUM(cr_return_amount) AS total_return_amount,
           SUM(cr_return_quantity) AS total_return_qty
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_item_sk
  ),
  wr_agg AS (
    SELECT wr_item_sk,
           SUM(wr_return_amt) AS total_web_return_amt,
           SUM(wr_return_quantity) AS total_web_return_qty
    FROM web_returns
    WHERE wr_return_amt > 0
    GROUP BY wr_item_sk
  ),
  joined AS (
    SELECT c.c_customer_id,
           i.i_item_id,
           i.i_category,
           i.i_brand,
           ss.total_sales,
           ss.total_qty,
           cr.total_return_amount,
           cr.total_return_qty,
           wr.total_web_return_amt,
           wr.total_web_return_qty,
           wp.wp_url,
           CASE WHEN cr.total_return_amount > 0 THEN 'Returned' ELSE 'Sold' END AS sale_status
    FROM ss_agg ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN cr_agg cr ON i.i_item_sk = cr.cr_item_sk
    LEFT JOIN wr_agg wr ON i.i_item_sk = wr.wr_item_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN item_attrs ia ON i.i_item_sk = ia.i_item_sk
    CROSS JOIN UNNEST(ia.attr_array) AS t(attr)
    WHERE i.i_units = 'Carton'
      AND c.c_preferred_cust_flag = 'Y'
  ),
  ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS global_row_num,
           ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS category_row_num,
           RANK() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS category_rank
    FROM joined
  )
SELECT c_customer_id,
       i_item_id,
       i_category,
       i_brand,
       total_sales,
       total_qty,
       total_return_amount,
       total_return_qty,
       total_web_return_amt,
       total_web_return_qty,
       wp_url,
       sale_status,
       global_row_num,
       category_row_num
FROM ranked
WHERE category_rank <= 3
UNION DISTINCT
SELECT c_customer_id,
       i_item_id,
       i_category,
       i_brand,
       total_sales,
       total_qty,
       total_return_amount,
       total_return_qty,
       total_web_return_amt,
       total_web_return_qty,
       wp_url,
       sale_status,
       global_row_num,
       category_row_num
FROM ranked
WHERE sale_status = 'Returned' AND category_rank <= 5
ORDER BY total_sales DESC
LIMIT 100
