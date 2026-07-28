WITH catalog_agg AS (
   SELECT i.i_category,
          SUM(cs.cs_ext_sales_price) AS total_sales,
          COUNT(*) AS sales_cnt,
          'catalog' AS sales_channel
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND d.d_quarter_seq = 12
     AND i.i_brand = 'Brand#12'
   GROUP BY i.i_category
),
web_agg AS (
   SELECT i.i_category,
          SUM(ws.ws_ext_sales_price) AS total_sales,
          COUNT(*) AS sales_cnt,
          'web' AS sales_channel
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND d.d_quarter_seq = 12
     AND i.i_brand = 'Brand#12'
   GROUP BY i.i_category
)
SELECT i_category,
       total_sales,
       sales_cnt,
       sales_channel
FROM catalog_agg
UNION ALL
SELECT i_category,
       total_sales,
       sales_cnt,
       sales_channel
FROM web_agg
ORDER BY i_category, sales_channel
