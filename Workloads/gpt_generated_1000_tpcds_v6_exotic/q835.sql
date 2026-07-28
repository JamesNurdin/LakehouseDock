WITH
  store_agg AS (
    SELECT
      d.d_year AS year,
      ca.ca_state AS state,
      SUM(ss.ss_net_paid) AS net_paid,
      SUM(ss.ss_ext_sales_price) AS sales_amount,
      COUNT(*) AS transactions
    FROM store_sales ss
    JOIN date_dim d          ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim td         ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND ca.ca_country = 'United States'
      AND ss.ss_quantity > 0
      AND td.t_meal_time = 'lunch'
    GROUP BY d.d_year, ca.ca_state
  ),

  web_sales_agg AS (
    SELECT
      d.d_year AS year,
      ca.ca_state AS state,
      sm.sm_type AS channel,
      SUM(ws.ws_net_paid) AS net_paid,
      SUM(ws.ws_ext_sales_price) AS sales_amount,
      COUNT(*) AS transactions
    FROM web_sales ws
    JOIN date_dim d          ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim td2        ON ws.ws_sold_time_sk = td2.t_time_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND ws.ws_quantity > 0
      AND sm.sm_type = 'AIR'
      AND td2.t_meal_time = 'dinner'
    GROUP BY d.d_year, ca.ca_state, sm.sm_type
  ),

  web_returns_agg AS (
    SELECT
      d.d_year AS year,
      ca.ca_state AS state,
      SUM(wr.wr_net_loss) AS returns_net_loss,
      COUNT(*) AS return_transactions
    FROM web_returns wr
    JOIN date_dim d          ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim td3        ON wr.wr_returned_time_sk = td3.t_time_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND wr.wr_return_quantity > 0
      AND td3.t_meal_time = 'breakfast'
    GROUP BY d.d_year, ca.ca_state
  )

SELECT
  sales.year,
  sales.state,
  sales.channel,
  SUM(sales.net_paid)           AS total_net_paid,
  SUM(sales.sales_amount)       AS total_sales_amount,
  SUM(sales.transactions)      AS total_transactions,
  CASE
    WHEN SUM(sales.net_paid) > 1000000 THEN 'High'
    WHEN SUM(sales.net_paid) > 500000  THEN 'Medium'
    ELSE 'Low'
  END                           AS revenue_level,
  COALESCE(r.returns_net_loss, 0) AS returns_net_loss
FROM (
  SELECT year, state, 'store' AS channel, net_paid, sales_amount, transactions
  FROM store_agg
  UNION ALL
  SELECT year, state, channel, net_paid, sales_amount, transactions
  FROM web_sales_agg
) AS sales
LEFT JOIN web_returns_agg r
  ON sales.year = r.year
 AND sales.state = r.state
GROUP BY sales.year, sales.state, sales.channel, r.returns_net_loss
HAVING SUM(sales.net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
