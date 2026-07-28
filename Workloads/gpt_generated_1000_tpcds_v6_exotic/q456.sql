SELECT
    w.web_name,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_order_cnt,
    MAX(cs.cs_list_price) AS max_list_price
FROM tpcds.catalog_sales cs
JOIN tpcds.date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.web_site w
  ON w.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1205
  AND w.web_county = 'Richland County'
  AND w.web_zip = '48059'
  AND cs.cs_ext_sales_price > 500
  AND cs.cs_quantity >= 2
GROUP BY w.web_name, d.d_year, d.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
