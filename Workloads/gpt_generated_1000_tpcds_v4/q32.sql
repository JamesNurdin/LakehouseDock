SELECT cs.cs_ship_date_sk,
       SUM(cs.cs_net_profit) AS total_profit
FROM tpcds.catalog_sales AS cs
WHERE cs.cs_ship_date_sk BETWEEN 2450830 AND 2450860
  AND cs.cs_ext_discount_amt > 1000
GROUP BY cs.cs_ship_date_sk
ORDER BY cs.cs_ship_date_sk DESC
