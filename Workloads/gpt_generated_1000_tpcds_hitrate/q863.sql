WITH sales_returns AS (
   SELECT 
      i.i_category AS i_category,
      i.i_item_id AS i_item_id,
      i.i_product_name AS i_product_name,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COALESCE(SUM(wr.wr_return_amt), 0) AS total_returns,
      CASE 
         WHEN COALESCE(SUM(wr.wr_return_amt), 0) > 0 THEN 'Has Returns'
         ELSE 'No Returns'
      END AS return_flag
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN web_returns wr 
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
   WHERE regexp_like(i.i_product_name, '^[A-Za-z]+[0-9]{2,}.*$')
     AND i.i_category LIKE '%Electronics%'
     AND EXISTS (
         SELECT 1 FROM web_returns wr2
         WHERE wr2.wr_item_sk = i.i_item_sk
           AND wr2.wr_return_amt > 50
     )
   GROUP BY i.i_category, i.i_item_id, i.i_product_name
),
ranked AS (
   SELECT
      sr.*, 
      ROW_NUMBER() OVER (PARTITION BY sr.i_category ORDER BY sr.total_sales DESC) AS rnk,
      CASE 
         WHEN sr.total_sales > (SELECT avg(ws_ext_sales_price) FROM web_sales) THEN 'Above Avg'
         ELSE 'Below Avg'
      END AS sales_comp
   FROM sales_returns sr
)
SELECT
   r.i_category,
   r.i_item_id,
   r.i_product_name,
   r.total_sales,
   r.total_returns,
   r.return_flag,
   r.sales_comp
FROM ranked r
WHERE r.rnk <= 5
ORDER BY r.i_category, r.rnk
LIMIT 100
