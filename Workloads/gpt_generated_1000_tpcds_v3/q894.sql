WITH sales_2001 AS (
    SELECT i.i_category AS category,
           sum(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND cc.cc_class = 'large'
    GROUP BY i.i_category
), returns_2001 AS (
    SELECT i.i_category AS category,
           sum(wr.wr_return_amt) AS total_returns
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category
)
SELECT category,
       total_sales AS metric,
       'catalog_sales' AS source
FROM sales_2001
WHERE total_sales > (SELECT avg(total_sales) FROM sales_2001)
UNION ALL
SELECT category,
       total_returns AS metric,
       'web_returns' AS source
FROM returns_2001
WHERE total_returns > (SELECT avg(total_returns) FROM returns_2001)
ORDER BY metric DESC
LIMIT 100
