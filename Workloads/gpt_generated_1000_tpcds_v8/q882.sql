WITH sampled_sales AS (
   SELECT *
   FROM store_sales
   TABLESAMPLE BERNOULLI (10)
),

sales_with_dim AS (
   SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_sold_time_sk,
      i.i_category,
      i.i_brand,
      ca.ca_state,
      cd.cd_gender,
      t.t_hour,
      ss.ss_net_paid,
      ss.ss_net_profit
   FROM sampled_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
),

store_ret_agg AS (
   SELECT
      sr.sr_ticket_number,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt
   FROM store_returns sr
   JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
   GROUP BY sr.sr_ticket_number
),

web_ret_agg AS (
   SELECT
      wr.wr_order_number AS ticket_number,
      SUM(wr.wr_return_amt) AS web_return_amt,
      COUNT(*) AS web_return_cnt
   FROM web_returns wr
   GROUP BY wr.wr_order_number
),

combined AS (
   SELECT
      swd.ss_ticket_number,
      swd.ss_customer_sk,
      swd.i_category,
      swd.i_brand,
      swd.ca_state,
      swd.cd_gender,
      swd.t_hour,
      swd.ss_net_paid,
      swd.ss_net_profit,
      COALESCE(sr.total_return_amt, 0) AS total_store_return,
      COALESCE(wr.web_return_amt, 0) AS total_web_return,
      (
         SELECT COUNT(DISTINCT ss2.ss_item_sk)
         FROM store_sales ss2
         WHERE ss2.ss_customer_sk = swd.ss_customer_sk
      ) AS distinct_items_by_customer,
      SUM(swd.ss_net_paid) OVER (
         PARTITION BY swd.i_category
         ORDER BY swd.t_hour
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS running_net_paid
   FROM sales_with_dim swd
   LEFT JOIN store_ret_agg sr ON swd.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN web_ret_agg wr ON swd.ss_ticket_number = wr.ticket_number
),

intersect_set AS (
   (SELECT ss_ticket_number FROM combined WHERE ss_net_profit > 1000)
   INTERSECT
   (SELECT ss_ticket_number FROM combined WHERE total_store_return > 500)
),

union_set AS (
   SELECT ss_ticket_number, 'high_profit_and_return' AS flag FROM intersect_set
   UNION DISTINCT
   SELECT ss_ticket_number, 'high_net_paid' AS flag
   FROM combined
   WHERE ss_net_paid > 5000
)

SELECT
   us.ss_ticket_number,
   us.flag,
   c.c_first_name,
   c.c_last_name,
   cd.cd_gender,
   ca.ca_state,
   i2.i_category,
   i2.i_brand,
   SUM(us_ss.ss_net_paid) AS total_net_paid,
   SUM(us_ss.ss_net_profit) AS total_net_profit,
   COUNT(DISTINCT us_ss.ss_item_sk) AS distinct_items,
   MAX(t2.t_hour) AS latest_hour
FROM union_set us
JOIN store_sales us_ss ON us.ss_ticket_number = us_ss.ss_ticket_number
JOIN customer c ON us_ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN item i2 ON us_ss.ss_item_sk = i2.i_item_sk
JOIN time_dim t2 ON us_ss.ss_sold_time_sk = t2.t_time_sk
GROUP BY GROUPING SETS (
   (us.ss_ticket_number, us.flag, c.c_first_name, c.c_last_name, cd.cd_gender, ca.ca_state, i2.i_category, i2.i_brand),
   (us.flag)
)
HAVING SUM(us_ss.ss_net_paid) > 1000
ORDER BY total_net_paid DESC, us.ss_ticket_number
