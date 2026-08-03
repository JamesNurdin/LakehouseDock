WITH cte AS (
   SELECT
       c.c_customer_id,
       cp.cp_department,
       SUM(cs.cs_net_paid) AS total_sales,
       SUM(sr.sr_return_amt) AS total_returns,
       SUM(ss.ss_ext_sales_price) AS store_sales_total,
       COUNT(DISTINCT cs.cs_order_number) AS orders,
       COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets
   FROM catalog_sales cs
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN store_sales ss
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN store_returns sr
     ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_customer_sk = c.c_customer_sk
   WHERE cp.cp_end_date_sk BETWEEN 2450900 AND 2451000
     AND cp.cp_start_date_sk > 2450800
     AND c.c_last_name IN ('Tillman', 'Little', 'Hill')
     AND c.c_first_name = 'Albert'
     AND sr.sr_return_quantity > 10
     AND sr.sr_addr_sk <> 1998511
     AND cs.cs_quantity >= 2
     AND cs.cs_ext_sales_price > 100
   GROUP BY c.c_customer_id, cp.cp_department
),
agg AS (
   SELECT
       cte.c_customer_id,
       cte.cp_department,
       cte.total_sales,
       cte.total_returns,
       cte.store_sales_total,
       (cte.total_sales - cte.total_returns) AS net_profit,
       cte.orders,
       cte.return_tickets
   FROM cte
),
pos_profit AS (
   SELECT * FROM agg WHERE net_profit > 0
),
neg_profit AS (
   SELECT * FROM agg WHERE net_profit <= 0
),
unioned AS (
   SELECT * FROM pos_profit
   UNION DISTINCT
   SELECT * FROM neg_profit
)
SELECT
    u.c_customer_id,
    u.cp_department,
    u.total_sales,
    u.total_returns,
    u.store_sales_total,
    u.net_profit,
    u.orders,
    u.return_tickets,
    row_number() OVER (ORDER BY u.net_profit DESC) AS rn
FROM unioned u
ORDER BY u.net_profit DESC, u.c_customer_id
