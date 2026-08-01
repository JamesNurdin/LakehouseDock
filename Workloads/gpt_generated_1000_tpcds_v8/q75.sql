WITH sales_agg AS (
    SELECT cs.cs_order_number AS order_number,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           CASE
               WHEN SUM(cs.cs_ext_sales_price) > 5000 THEN 'High'
               WHEN SUM(cs.cs_ext_sales_price) > 2000 THEN 'Medium'
               ELSE 'Low'
           END AS sales_tier
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE i.i_category = 'Shoes'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY cs.cs_order_number
    HAVING SUM(cs.cs_ext_sales_price) > 1000
),
returns_agg AS (
    SELECT wr.wr_order_number AS order_number,
           SUM(wr.wr_return_amt) AS total_return,
           CASE
               WHEN SUM(wr.wr_return_amt) > 2000 THEN 'High'
               WHEN SUM(wr.wr_return_amt) > 1000 THEN 'Medium'
               ELSE 'Low'
           END AS return_tier
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE r.r_reason_desc LIKE '%product%'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY wr.wr_order_number
    HAVING SUM(wr.wr_return_amt) > 500
),
intersect_orders AS (
    SELECT order_number, sales_tier
    FROM sales_agg
    INTERSECT
    SELECT order_number, return_tier
    FROM returns_agg
)
SELECT io.order_number,
       io.sales_tier,
       COUNT(*) OVER () AS total_matching_orders
FROM intersect_orders io
ORDER BY io.sales_tier, io.order_number
