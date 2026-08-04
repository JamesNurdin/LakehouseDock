WITH
  agg_store_sales AS (
    SELECT
      ss_customer_sk,
      ss_sold_date_sk,
      SUM(ss_ext_sales_price) AS store_sales_sum,
      COUNT(*) AS store_sales_cnt
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_ext_sales_price > 1000
    GROUP BY ss_customer_sk, ss_sold_date_sk
  ),
  store_customers AS (
    SELECT ss_customer_sk FROM store_sales
  ),
  web_customers AS (
    SELECT ws_bill_customer_sk FROM web_sales
  ),
  cust_store_only AS (
    SELECT ss_customer_sk FROM store_customers
    EXCEPT
    SELECT ws_bill_customer_sk FROM web_customers
  ),
  joined_base AS (
    SELECT
      agg.ss_customer_sk,
      agg.ss_sold_date_sk,
      agg.store_sales_sum,
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_state,
      ca.ca_country,
      hd.hd_buy_potential,
      t.t_hour,
      cs.cs_ext_sales_price,
      ws.ws_ext_sales_price,
      wr.wr_return_amt,
      sr.sr_return_amt,
      wp.wp_web_page_sk
    FROM agg_store_sales agg
    JOIN customer c ON agg.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON agg.ss_sold_date_sk = t.t_time_sk
    LEFT JOIN catalog_sales cs
      ON cs.cs_bill_customer_sk = c.c_customer_sk
     AND cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN web_returns wr
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
     AND wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr
      ON sr.sr_customer_sk = c.c_customer_sk
     AND sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ca.ca_country = 'United States'
      AND hd.hd_buy_potential = '1001-5000'
      AND t.t_hour BETWEEN 9 AND 17
      AND cs.cs_ext_sales_price > 2000
      AND ws.ws_ext_tax > 50
      AND wr.wr_return_amt > 100
      AND sr.sr_return_amt > 200
  ),
  sel1 AS (
    SELECT * FROM joined_base WHERE store_sales_sum > 5000
  ),
  sel2 AS (
    SELECT * FROM joined_base WHERE ws_ext_sales_price > 3000
  ),
  unioned AS (
    SELECT * FROM sel1
    UNION
    SELECT * FROM sel2
  )
SELECT
  ub.c_first_name,
  ub.c_last_name,
  ub.ca_state,
  ub.hd_buy_potential,
  ub.t_hour,
  SUM(ub.store_sales_sum) AS total_store_sales,
  AVG(ub.cs_ext_sales_price) AS avg_catalog_sales,
  COUNT(DISTINCT ub.c_customer_sk) AS distinct_customers,
  (
    SELECT SUM(ws2.ws_net_paid_inc_tax)
    FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = ub.c_customer_sk
      AND ws2.ws_sold_date_sk = ub.ss_sold_date_sk
  ) AS web_net_paid_total
FROM unioned ub
WHERE ub.c_customer_sk IN (SELECT ss_customer_sk FROM cust_store_only)
GROUP BY CUBE (ub.hd_buy_potential, ub.ca_state),
         ub.c_first_name,
         ub.c_last_name,
         ub.t_hour,
         ub.c_customer_sk,
         ub.ss_sold_date_sk,
         ub.store_sales_sum,
         ub.cs_ext_sales_price
HAVING SUM(ub.store_sales_sum) > 10000
ORDER BY total_store_sales DESC
LIMIT 100
