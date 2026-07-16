SELECT d.d_year, sum(cs.cs_net_paid) AS total_net_paid
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE d.d_year BETWEEN 1998 AND 1999
GROUP BY d.d_year
ORDER BY d.d_year
