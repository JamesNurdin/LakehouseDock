WITH first_set AS (
   SELECT
       c.c_customer_sk,
       c.c_customer_id,
       s.ss_ticket_number,
       s.ss_sold_date_sk,
       s.ss_net_paid,
       LAG(s.ss_net_paid) OVER (PARTITION BY c.c_customer_sk ORDER BY s.ss_sold_date_sk) AS lag_net_paid,
       CASE WHEN s.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
       SUM(s.ss_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY s.ss_sold_date_sk
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid,
       lr.total_return_amt
   FROM store_sales s
   JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
   CROSS JOIN LATERAL (
       SELECT COALESCE(SUM(r.sr_return_amt), 0) AS total_return_amt
       FROM store_returns r
       WHERE r.sr_item_sk = s.ss_item_sk
         AND r.sr_customer_sk = c.c_customer_sk
         AND r.sr_return_quantity > 0
   ) lr
   WHERE s.ss_wholesale_cost > 30
     AND s.ss_ext_discount_amt < 5000
     AND c.c_last_review_date > 2452500
     AND c.c_first_shipto_date_sk BETWEEN 2449000 AND 2452000
     AND EXISTS (
         SELECT 1 FROM store_returns r2
         WHERE r2.sr_customer_sk = c.c_customer_sk
           AND r2.sr_fee > 10
     )
     AND s.ss_net_paid_inc_tax > 0
),
second_set AS (
   SELECT
       c.c_customer_sk,
       c.c_customer_id,
       s.ss_ticket_number,
       s.ss_sold_date_sk,
       s.ss_net_paid,
       LAG(s.ss_net_paid) OVER (PARTITION BY c.c_customer_sk ORDER BY s.ss_sold_date_sk) AS lag_net_paid,
       CASE WHEN s.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
       SUM(s.ss_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY s.ss_sold_date_sk
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid,
       lr.total_return_amt
   FROM store_sales s
   JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
   CROSS JOIN LATERAL (
       SELECT COALESCE(SUM(r.sr_return_amt), 0) AS total_return_amt
       FROM store_returns r
       WHERE r.sr_item_sk = s.ss_item_sk
         AND r.sr_customer_sk = c.c_customer_sk
         AND r.sr_return_ship_cost < 1000
   ) lr
   WHERE s.ss_wholesale_cost BETWEEN 30 AND 45
     AND s.ss_ext_discount_amt BETWEEN 100 AND 4000
     AND c.c_last_review_date BETWEEN 2452400 AND 2452600
     AND c.c_first_shipto_date_sk < 2451000
     AND EXISTS (
         SELECT 1 FROM store_returns r3
         WHERE r3.sr_customer_sk = c.c_customer_sk
           AND r3.sr_fee BETWEEN 5 AND 50
     )
     AND s.ss_net_paid IS NOT NULL
),
union_set AS (
   SELECT * FROM first_set
   UNION
   SELECT * FROM second_set
),
intersect_keys AS (
   SELECT c_customer_sk FROM first_set
   INTERSECT
   SELECT c_customer_sk FROM second_set
)
SELECT
   us.c_customer_id,
   us.ss_ticket_number,
   us.ss_sold_date_sk,
   us.ss_net_paid,
   us.lag_net_paid,
   us.running_net_paid,
   us.profit_status,
   us.total_return_amt
FROM union_set us
JOIN intersect_keys ik ON us.c_customer_sk = ik.c_customer_sk
ORDER BY us.running_net_paid DESC, us.ss_sold_date_sk
LIMIT 100
