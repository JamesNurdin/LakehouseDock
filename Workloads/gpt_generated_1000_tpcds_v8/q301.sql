SELECT
    cs.cs_order_number,
    cs.cs_net_paid_inc_tax,
    td.t_hour,
    td.t_shift
FROM tpcds.catalog_sales AS cs
JOIN tpcds.time_dim AS td
  ON cs.cs_sold_time_sk = td.t_time_sk
WHERE td.t_sub_shift = 'afternoon'
  AND cs.cs_net_paid_inc_tax > 1500
LIMIT 100
