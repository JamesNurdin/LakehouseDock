WITH
  chain_a AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_bill_customer_sk,
      ws.ws_net_paid,
      ws.ws_quantity,
      ws.ws_net_profit,
      cd.cd_gender,
      hd.hd_buy_potential,
      d.d_year,
      w.w_country,
      wp.wp_type,
      wr.wr_return_amt,
      CASE WHEN ws.ws_net_profit > 0 THEN 1 ELSE 0 END AS profit_flag,
      ROW_NUMBER() OVER (ORDER BY ws.ws_sold_date_sk) AS rn
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'F'
      AND w.w_country = 'United States'
      AND hd.hd_buy_potential = '>10000'
  ),
  chain_b AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_bill_customer_sk,
      ws.ws_net_paid,
      ws.ws_quantity,
      ws.ws_net_profit,
      cd.cd_gender,
      hd.hd_buy_potential,
      d.d_year,
      w.w_country,
      wp.wp_type,
      wr.wr_return_amt,
      CASE WHEN ws.ws_net_profit > 0 THEN 1 ELSE 0 END AS profit_flag,
      ROW_NUMBER() OVER (ORDER BY ws.ws_sold_date_sk) AS rn
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE d.d_year = 2002
      AND cd.cd_gender = 'M'
      AND w.w_country = 'United States'
      AND hd.hd_buy_potential = '5001-10000'
  ),
  union_set AS (
    SELECT ws_order_number FROM chain_a
    UNION
    SELECT ws_order_number FROM chain_b
  ),
  except_set AS (
    SELECT ws_order_number FROM chain_a
    EXCEPT
    SELECT ws_order_number FROM chain_b
  ),
  intersect_set AS (
    SELECT ws_order_number FROM chain_a
    INTERSECT
    SELECT ws_order_number FROM chain_b
  ),
  full_outer AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      wp.wp_web_page_sk,
      wp.wp_type
    FROM customer c
    FULL OUTER JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
  )
SELECT
  a.d_year,
  a.cd_gender,
  a.hd_buy_potential,
  COUNT(DISTINCT a.ws_order_number) AS order_cnt,
  SUM(a.ws_net_paid) AS total_net_paid,
  AVG(a.ws_quantity) AS avg_quantity,
  MAX(a.wr_return_amt) AS max_return_amt,
  SUM(CASE WHEN a.profit_flag = 1 THEN a.ws_net_paid ELSE 0 END) AS profit_net_paid,
  COUNT(DISTINCT f.c_customer_sk) AS customers_with_pages,
  COUNT(DISTINCT f.wp_web_page_sk) AS pages_with_customers
FROM chain_a a
JOIN chain_b b ON a.ws_order_number = b.ws_order_number
JOIN full_outer f ON a.ws_bill_customer_sk = f.c_customer_sk
WHERE a.ws_order_number IN (SELECT ws_order_number FROM intersect_set)
GROUP BY a.d_year, a.cd_gender, a.hd_buy_potential
HAVING COUNT(DISTINCT a.ws_order_number) > 10
ORDER BY total_net_paid DESC
LIMIT 100
