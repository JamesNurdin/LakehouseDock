SELECT department,
       total_sales,
       total_profit
FROM (
    SELECT cp.cp_department AS department,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           SUM(cs.cs_net_profit) AS total_profit
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_catalog_number BETWEEN 10 AND 15
      AND cs.cs_ext_sales_price > 2000
    GROUP BY cp.cp_department

    UNION ALL

    SELECT cp.cp_department AS department,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           SUM(cs.cs_net_profit) AS total_profit
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'Seasonal'
      AND cs.cs_net_profit > 0
    GROUP BY cp.cp_department
) AS combined
ORDER BY total_sales DESC
