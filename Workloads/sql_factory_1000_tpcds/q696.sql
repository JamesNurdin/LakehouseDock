SELECT
    d.d_date AS sale_date,
    cs.cs_item_sk AS item_sk,
    SUM(cs.cs_quantity) AS catalog_quantity,
    SUM(ss.ss_quantity) AS store_quantity,
    SUM(cs.cs_ext_sales_price) AS catalog_sales,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    (SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price)) AS total_sales,
    CASE
        WHEN SUM(cs.cs_ext_sales_price) > SUM(ss.ss_ext_sales_price) THEN 'Catalog'
        WHEN SUM(cs.cs_ext_sales_price) < SUM(ss.ss_ext_sales_price) THEN 'Store'
        ELSE 'Tie'
    END AS higher_channel,
    RANK() OVER (PARTITION BY d.d_date ORDER BY (SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price)) DESC) AS daily_item_rank
FROM catalog_sales cs
JOIN store_sales ss
  ON cs.cs_item_sk = ss.ss_item_sk
 AND cs.cs_sold_date_sk = ss.ss_sold_date_sk
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
GROUP BY d.d_date, cs.cs_item_sk
HAVING SUM(cs.cs_quantity) > 0 OR SUM(ss.ss_quantity) > 0
ORDER BY d.d_date, daily_item_rank
