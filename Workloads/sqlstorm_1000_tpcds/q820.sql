WITH combined_sales AS (
  SELECT
    d.d_year,
    i.i_item_sk,
    i.i_product_name,
    i.i_category,
    i.i_class,
    SUM(cs.cs_ext_sales_price) AS catalog_sales,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    SUM(ws.ws_net_profit) AS web_profit
  FROM
    date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk AND ss.ss_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year = 2002
  GROUP BY d.d_year, i.i_item_sk, i.i_product_name, i.i_category, i.i_class
)
SELECT
  d_year,
  i_item_sk,
  i_product_name,
  i_category,
  i_class,
  catalog_sales + store_sales + web_sales AS total_sales,
  catalog_profit + store_profit + web_profit AS total_profit
FROM combined_sales
WHERE (catalog_sales + store_sales + web_sales) > 10000
ORDER BY total_profit DESC
LIMIT 20
