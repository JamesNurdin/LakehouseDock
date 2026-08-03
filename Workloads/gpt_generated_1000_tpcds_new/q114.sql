WITH
  ss_agg AS (
    SELECT
      ss_ticket_number,
      ss_customer_sk,
      ss_sold_date_sk,
      ss_sold_time_sk,
      SUM(ss_net_paid) AS total_net_paid,
      SUM(ss_ext_sales_price) AS total_sales_price,
      COUNT(*) AS cnt_items
    FROM store_sales
    WHERE ss_quantity > 1
      AND ss_sales_price > 20
      AND ss_sold_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY ss_ticket_number, ss_customer_sk, ss_sold_date_sk, ss_sold_time_sk
  ),
  sr_agg AS (
    SELECT
      sr_ticket_number,
      SUM(sr_return_amt) AS total_return_amt,
      COUNT(*) AS cnt_returns
    FROM store_returns
    GROUP BY sr_ticket_number
  ),
  high_sales AS (
    SELECT ss_customer_sk AS customer_sk
    FROM ss_agg
    GROUP BY ss_customer_sk
    HAVING SUM(total_net_paid) > 10000
  ),
  high_returns AS (
    SELECT wr_returning_customer_sk AS customer_sk
    FROM web_returns
    WHERE wr_return_amt > 100
    GROUP BY wr_returning_customer_sk
  ),
  intersect_customers AS (
    SELECT customer_sk FROM high_sales
    INTERSECT
    SELECT customer_sk FROM high_returns
  ),
  base AS (
    SELECT
      c.c_customer_id               AS customer_id,
      ca.ca_city                     AS city,
      ca.ca_state                    AS state,
      cd.cd_gender                   AS gender,
      hd.hd_income_band_sk           AS income_band,
      d.d_year                       AS year,
      t.t_hour                       AS hour,
      r.r_reason_desc                AS reason_desc,
      ss_agg.total_net_paid,
      ss_agg.total_sales_price,
      ss_agg.cnt_items,
      sr_agg.total_return_amt,
      sr_agg.cnt_returns,
      ARRAY[ss_agg.total_net_paid, sr_agg.total_return_amt] AS metric_array
    FROM intersect_customers ic
    JOIN customer c ON ic.customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN ss_agg ON ss_agg.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss_agg.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss_agg.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN sr_agg ON sr_agg.sr_ticket_number = ss_agg.ss_ticket_number
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss_agg.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
      AND wr.wr_returned_date_sk = d.d_date_sk
      AND wr.wr_returned_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND (r.r_reason_desc LIKE '%damaged%' OR r.r_reason_desc IS NULL)
  )
SELECT
  customer_id,
  city,
  state,
  gender,
  income_band,
  year,
  hour,
  reason_desc,
  total_net_paid,
  total_sales_price,
  cnt_items,
  total_return_amt,
  cnt_returns,
  metric,
  RANK() OVER (PARTITION BY year ORDER BY total_net_paid DESC) AS sales_rank,
  ROW_NUMBER() OVER (ORDER BY total_return_amt DESC) AS return_rownum
FROM base
CROSS JOIN UNNEST(metric_array) AS t(metric)
ORDER BY sales_rank ASC, total_return_amt DESC
LIMIT 100
