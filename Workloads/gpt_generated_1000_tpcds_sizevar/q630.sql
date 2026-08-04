WITH cat_sample AS (
   SELECT *
   FROM catalog_sales TABLESAMPLE BERNOULLI (5)
),

-- Catalog sales joined with its dimensions (6 joins + a LATERAL subquery)
cat_join AS (
   SELECT
       cs.cs_bill_customer_sk AS customer_sk,
       cp.cp_department        AS department,
       td.t_hour               AS hour_of_day,
       cs.cs_quantity,
       cs.cs_sales_price,
       ca_bill.ca_state        AS bill_state,
       cd_bill.cd_gender       AS bill_gender,
       lt.line_amount,
       cs.cs_net_profit
   FROM cat_sample cs
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN time_dim td
     ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN customer_demographics cd_bill
     ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN customer_address ca_bill
     ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
   JOIN customer_demographics cd_ship
     ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
   JOIN customer_address ca_ship
     ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
   CROSS JOIN LATERAL (
       SELECT cs.cs_quantity * cs.cs_sales_price AS line_amount
   ) lt
),

-- Store sales (and returns) joined with their dimensions (8 joins)
store_join AS (
   SELECT
       ss.ss_customer_sk       AS customer_sk,
       'STORE'                 AS department,
       td.t_hour               AS hour_of_day,
       ss.ss_quantity,
       ss.ss_sales_price,
       ca.ca_state             AS store_state,
       cd.cd_gender            AS store_gender,
       lt.line_amount,
       ss.ss_net_profit,
       r.r_reason_desc
   FROM store_sales ss
   JOIN time_dim td
     ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN store_returns sr
     ON ss.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN time_dim td_ret
     ON sr.sr_return_time_sk = td_ret.t_time_sk
   LEFT JOIN customer_demographics cd_ret
     ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
   LEFT JOIN customer_address ca_ret
     ON sr.sr_addr_sk = ca_ret.ca_address_sk
   CROSS JOIN LATERAL (
       SELECT ss.ss_quantity * ss.ss_sales_price AS line_amount
   ) lt
),

-- Union of the two flows (distinct)
union_all AS (
   SELECT
       customer_sk,
       department,
       hour_of_day,
       line_amount,
       cs_net_profit AS profit,
       bill_state AS state,
       bill_gender AS gender
   FROM cat_join
   UNION DISTINCT
   SELECT
       customer_sk,
       department,
       hour_of_day,
       line_amount,
       ss_net_profit AS profit,
       store_state AS state,
       store_gender AS gender
   FROM store_join
),

-- Customers appearing in both flows (INTERSECT)
intersect_customers AS (
   SELECT customer_sk FROM cat_join WHERE cs_quantity > 5
   INTERSECT
   SELECT customer_sk FROM store_join WHERE ss_quantity > 2
),

-- Customers only in catalog flow (EXCEPT)
except_customers AS (
   SELECT customer_sk FROM cat_join
   EXCEPT
   SELECT customer_sk FROM store_join
),

final AS (
   SELECT
       department,
       state,
       hour_of_day,
       COUNT(DISTINCT u.customer_sk)                     AS unique_customers,
       SUM(u.line_amount)                               AS total_sales,
       SUM(u.profit)                                    AS total_profit
   FROM union_all u
   WHERE u.customer_sk IN (SELECT customer_sk FROM intersect_customers)
     AND u.customer_sk NOT IN (SELECT customer_sk FROM except_customers)
   GROUP BY department, state, hour_of_day
)

SELECT *
FROM final
ORDER BY total_sales DESC
LIMIT 100
