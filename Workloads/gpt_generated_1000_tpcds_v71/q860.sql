WITH joined_data AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_geography_class,
    s.s_company_id,
    td_sales.t_hour AS sales_hour,
    td_sales.t_minute AS sales_minute,
    cs.cs_net_profit,
    sr.sr_refunded_cash,
    c.c_customer_sk
  FROM store s
  JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
  JOIN time_dim td_return ON sr.sr_return_time_sk = td_return.t_time_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN time_dim td_sales ON cs.cs_sold_time_sk = td_sales.t_time_sk
  JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
  WHERE s.s_geography_class = 'Unknown'
    AND s.s_company_id = 1
    AND td_sales.t_minute IN (1, 3, 8, 15)
    AND cs.cs_net_profit > 100.00
    AND sr.sr_return_amt_inc_tax < 1500.00
    AND wp.wp_char_count > 500
),
agg_by_store_hour AS (
  SELECT
    s_store_id,
    s_store_name,
    sales_hour,
    SUM(cs_net_profit) AS total_profit,
    SUM(sr_refunded_cash) AS total_refunded,
    COUNT(DISTINCT c_customer_sk) AS cust_cnt
  FROM joined_data
  GROUP BY s_store_id, s_store_name, sales_hour
)
SELECT
  sales_hour,
  AVG(total_profit) AS avg_profit,
  SUM(total_refunded) AS sum_refunded,
  AVG(cust_cnt) AS avg_customers
FROM agg_by_store_hour
GROUP BY sales_hour
HAVING AVG(total_profit) > 200.00
ORDER BY avg_profit DESC
LIMIT 100
