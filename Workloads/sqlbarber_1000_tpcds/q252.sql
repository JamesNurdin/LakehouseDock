SELECT d_year, SUM(cs_net_paid) AS total_net_paid FROM catalog_sales JOIN date_dim ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk WHERE d_year = 1926 GROUP BY d_year
