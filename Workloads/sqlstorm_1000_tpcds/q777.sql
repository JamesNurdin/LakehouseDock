WITH
sales_all AS (
   SELECT ss_sold_date_sk AS date_sk,
          ss_customer_sk AS cust_sk,
          ss_ticket_number AS order_no,
          ss_item_sk AS item_sk,
          ss_quantity AS qty,
          ss_net_paid AS net_paid,
          ss_net_profit AS net_profit,
          'store' AS channel
   FROM store_sales
   UNION ALL
   SELECT cs_sold_date_sk,
          cs_bill_customer_sk,
          cs_order_number,
          cs_item_sk,
          cs_quantity,
          cs_net_paid,
          cs_net_profit,
          'catalog'
   FROM catalog_sales
   UNION ALL
   SELECT ws_sold_date_sk,
          ws_bill_customer_sk,
          ws_order_number,
          ws_item_sk,
          ws_quantity,
          ws_net_paid,
          ws_net_profit,
          'web'
   FROM web_sales
),
returns_all AS (
   SELECT sr_returned_date_sk AS date_sk,
          sr_customer_sk AS cust_sk,
          sr_ticket_number AS order_no,
          sr_item_sk AS item_sk,
          sr_return_quantity AS qty,
          sr_net_loss AS net_loss,
          sr_reason_sk AS reason_sk,
          'store' AS channel
   FROM store_returns
   UNION ALL
   SELECT cr_returned_date_sk,
          cr_refunded_customer_sk,
          cr_order_number,
          cr_item_sk,
          cr_return_quantity,
          cr_net_loss,
          cr_reason_sk,
          'catalog'
   FROM catalog_returns
   UNION ALL
   SELECT wr_returned_date_sk,
          wr_refunded_customer_sk,
          wr_order_number,
          wr_item_sk,
          wr_return_quantity,
          wr_net_loss,
          wr_reason_sk,
          'web'
   FROM web_returns
),
customer_state AS (
   SELECT c.c_customer_sk,
          ca.ca_state
   FROM customer c
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
state_sales_agg AS (
   SELECT s.s_state AS state,
          SUM(ss.ss_net_profit) AS state_total_profit
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   GROUP BY s.s_state
),
state_cc_agg AS (
   SELECT cc.cc_state AS state,
          SUM(cc.cc_employees) AS total_employees,
          AVG(cc.cc_gmt_offset) AS avg_gmt_offset
   FROM call_center cc
   GROUP BY cc.cc_state
),
state_combined AS (
   SELECT COALESCE(ss.state, cc.state) AS state,
          COALESCE(ss.state_total_profit, 0) AS state_total_profit,
          COALESCE(cc.total_employees, 0) AS total_employees,
          COALESCE(cc.avg_gmt_offset, 0) AS avg_gmt_offset
   FROM state_sales_agg ss
   FULL OUTER JOIN state_cc_agg cc ON ss.state = cc.state
),
customer_agg AS (
   SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      COALESCE(cd.cd_gender, 'U') AS gender,
      SUM(COALESCE(s.net_profit, 0)) AS total_profit,
      COUNT(DISTINCT s.order_no) AS distinct_orders,
      SUM(COALESCE(s.qty, 0)) AS total_quantity,
      COUNT(DISTINCT s.item_sk) AS distinct_items_sold,
      SUM(COALESCE(r.net_loss, 0)) AS total_return_loss,
      COUNT(DISTINCT r.order_no) AS distinct_return_orders,
      COUNT(DISTINCT r.item_sk) AS distinct_items_returned
   FROM customer c
   LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN sales_all s ON c.c_customer_sk = s.cust_sk
   LEFT JOIN returns_all r ON c.c_customer_sk = r.cust_sk AND s.order_no = r.order_no
   GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
ranking AS (
   SELECT
      ca.*,
      ROW_NUMBER() OVER (ORDER BY ca.total_profit DESC) AS profit_rank,
      CASE
         WHEN ca.total_profit > 100000 THEN 'HIGH'
         WHEN ca.total_profit > 50000 THEN 'MEDIUM'
         ELSE 'LOW'
      END AS profit_bucket,
      CONCAT(ca.c_first_name, ' ', ca.c_last_name, ' (', COALESCE(ca.gender, 'U'), ')') AS customer_profile
   FROM customer_agg ca
)
SELECT
   r.c_customer_sk,
   r.customer_profile,
   r.total_profit,
   r.total_return_loss,
   r.total_quantity,
   r.distinct_orders,
   r.profit_rank,
   r.profit_bucket,
   COALESCE(sc.state_total_profit, 0) AS state_total_profit,
   COALESCE(sc.total_employees, 0) AS state_total_employees,
   COALESCE(sc.avg_gmt_offset, 0) AS state_avg_gmt_offset,
   (SELECT COUNT(*)
    FROM returns_all ra
    JOIN date_dim d ON ra.date_sk = d.d_date_sk
    WHERE ra.cust_sk = r.c_customer_sk
      AND d.d_date >= DATE '2024-10-01' - INTERVAL '30' DAY) AS recent_return_count_30d,
   SUM(r.total_profit) OVER (ORDER BY r.total_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM ranking r
LEFT JOIN customer_state cs ON r.c_customer_sk = cs.c_customer_sk
LEFT JOIN state_combined sc ON cs.ca_state = sc.state
WHERE r.profit_rank <= 100
UNION ALL
SELECT
   r.c_customer_sk,
   r.customer_profile,
   r.total_profit,
   r.total_return_loss,
   r.total_quantity,
   r.distinct_orders,
   r.profit_rank,
   r.profit_bucket,
   COALESCE(sc.state_total_profit, 0) AS state_total_profit,
   COALESCE(sc.total_employees, 0) AS state_total_employees,
   COALESCE(sc.avg_gmt_offset, 0) AS state_avg_gmt_offset,
   (SELECT COUNT(*)
    FROM returns_all ra
    JOIN date_dim d ON ra.date_sk = d.d_date_sk
    WHERE ra.cust_sk = r.c_customer_sk
      AND d.d_date >= DATE '2024-10-01' - INTERVAL '30' DAY) AS recent_return_count_30d,
   SUM(r.total_profit) OVER (ORDER BY r.total_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM ranking r
LEFT JOIN customer_state cs ON r.c_customer_sk = cs.c_customer_sk
LEFT JOIN state_combined sc ON cs.ca_state = sc.state
WHERE r.total_return_loss > 5000
  AND r.profit_rank > 100
ORDER BY total_profit DESC
LIMIT 200
