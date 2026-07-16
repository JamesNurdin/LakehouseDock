WITH unified_sales AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_ext_sales_price AS sales_amount,
         cs.cs_net_profit AS profit,
         cs.cs_ext_discount_amt AS discount_amt,
         cs.cs_ext_list_price AS list_price,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_ext_sales_price,
         ss.ss_net_profit,
         ss.ss_ext_discount_amt,
         ss.ss_ext_list_price,
         'store'
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_item_sk,
         ws.ws_ext_sales_price,
         ws.ws_net_profit,
         ws.ws_ext_discount_amt,
         ws.ws_ext_list_price,
         'web'
  FROM web_sales ws
),
sales_with_date AS (
  SELECT us.*,
         d.d_year
  FROM unified_sales us
  JOIN date_dim d ON us.date_sk = d.d_date_sk
  WHERE d.d_year = 2001
),
sales_agg AS (
  SELECT i.i_item_id,
         i.i_product_name,
         i.i_category,
         i.i_brand,
         swd.d_year,
         SUM(CASE WHEN swd.channel = 'catalog' THEN swd.sales_amount ELSE 0 END) AS catalog_sales,
         SUM(CASE WHEN swd.channel = 'store' THEN swd.sales_amount ELSE 0 END) AS store_sales,
         SUM(CASE WHEN swd.channel = 'web' THEN swd.sales_amount ELSE 0 END) AS web_sales,
         SUM(swd.sales_amount) AS total_sales,
         SUM(swd.profit) AS total_profit,
         AVG(CASE WHEN swd.list_price > 0 THEN swd.discount_amt / swd.list_price ELSE 0 END) AS avg_discount_ratio
  FROM sales_with_date swd
  JOIN item i ON swd.item_sk = i.i_item_sk
  GROUP BY i.i_item_id, i.i_product_name, i.i_category, i.i_brand, swd.d_year
)
SELECT *
FROM (
    SELECT sa.*,
           ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY sa.total_sales DESC) AS sales_rank
    FROM sales_agg sa
) ranked
WHERE sales_rank <= 10
ORDER BY d_year, total_sales DESC
