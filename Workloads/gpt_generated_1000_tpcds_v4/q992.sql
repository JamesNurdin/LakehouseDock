WITH
  store_sales AS (
    SELECT
      d.d_year AS year,
      CASE WHEN cs.cs_net_profit / NULLIF(cs.cs_ext_sales_price, 0) > 0.2 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_state = 'CA'
    GROUP BY
      d.d_year,
      CASE WHEN cs.cs_net_profit / NULLIF(cs.cs_ext_sales_price, 0) > 0.2 THEN 'HIGH' ELSE 'LOW' END
    HAVING SUM(cs.cs_ext_sales_price) > 10000
  ),
  website_sales AS (
    SELECT
      d.d_year AS year,
      CASE WHEN cs.cs_net_profit / NULLIF(cs.cs_ext_sales_price, 0) > 0.15 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE w.web_tax_percentage > 0.05
    GROUP BY
      d.d_year,
      CASE WHEN cs.cs_net_profit / NULLIF(cs.cs_ext_sales_price, 0) > 0.15 THEN 'HIGH' ELSE 'LOW' END
    HAVING SUM(cs.cs_ext_sales_price) > 15000
  )
SELECT year, profit_category, total_sales, total_profit
FROM store_sales
UNION ALL
SELECT year, profit_category, total_sales, total_profit
FROM website_sales
ORDER BY year DESC, profit_category
LIMIT 100
