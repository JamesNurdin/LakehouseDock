SELECT
    c.c_customer_id,
    hd.hd_demo_sk,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales
FROM catalog_sales cs
INNER JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
INNER JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND cs.cs_ext_wholesale_cost > 1000
GROUP BY c.c_customer_id, hd.hd_demo_sk

UNION ALL

SELECT
    c.c_customer_id,
    hd.hd_demo_sk,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales
FROM catalog_sales cs
INNER JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
INNER JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
INNER JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE wp.wp_link_count > 5
  AND wp.wp_rec_end_date >= DATE '2000-01-01'
GROUP BY c.c_customer_id, hd.hd_demo_sk

ORDER BY total_sales DESC
LIMIT 100
