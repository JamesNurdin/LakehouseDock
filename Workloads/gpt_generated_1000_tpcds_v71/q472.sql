WITH cat_agg AS (
   SELECT
       cr.cr_refunded_customer_sk AS cust_sk,
       SUM(cr.cr_net_loss)                     AS cat_net_loss,
       COUNT(DISTINCT cr.cr_order_number)      AS cat_orders,
       MAX(cr.cr_return_amount)                AS cat_max_return_amt
   FROM catalog_returns cr
   WHERE cr.cr_returned_date_sk BETWEEN 2450990 AND 2451100
     AND cr.cr_return_quantity > 0
   GROUP BY cr.cr_refunded_customer_sk
),
store_agg AS (
   SELECT
       sr.sr_customer_sk AS cust_sk,
       SUM(sr.sr_net_loss)                AS store_net_loss,
       COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
       MAX(sr.sr_return_amt)               AS store_max_return_amt
   FROM store_returns sr
   WHERE sr.sr_returned_date_sk BETWEEN 2450990 AND 2451100
   GROUP BY sr.sr_customer_sk
),
web_agg AS (
   SELECT
       wr.wr_refunded_customer_sk AS cust_sk,
       SUM(wr.wr_net_loss)                AS web_net_loss,
       COUNT(DISTINCT wr.wr_order_number) AS web_orders,
       MAX(wr.wr_return_amt)               AS web_max_return_amt
   FROM web_returns wr
   WHERE wr.wr_returned_date_sk BETWEEN 2450990 AND 2451100
   GROUP BY wr.wr_refunded_customer_sk
),
customer_return_agg AS (
   SELECT
       c.c_customer_sk,
       c.c_customer_id,
       c.c_birth_country,
       c.c_preferred_cust_flag,
       c.c_birth_year,
       c.c_birth_month,
       COALESCE(cat.cat_net_loss, 0)   + COALESCE(store.store_net_loss, 0)   + COALESCE(web.web_net_loss, 0)   AS total_net_loss,
       COALESCE(cat.cat_max_return_amt, 0)   AS cat_max_return_amt,
       COALESCE(store.store_max_return_amt, 0) AS store_max_return_amt,
       COALESCE(web.web_max_return_amt, 0)   AS web_max_return_amt
   FROM customer c
   LEFT JOIN cat_agg   cat   ON cat.cust_sk   = c.c_customer_sk
   LEFT JOIN store_agg store ON store.cust_sk = c.c_customer_sk
   LEFT JOIN web_agg   web   ON web.cust_sk   = c.c_customer_sk
   WHERE c.c_birth_country      = 'United States'
     AND c.c_preferred_cust_flag = 'Y'
     AND c.c_birth_year BETWEEN 1950 AND 1990
     AND c.c_birth_month = 7
)
SELECT
    cp.cp_department,
    sm.sm_type,
    w.w_city,
    s.s_state,
    AVG(cra.total_net_loss) AS avg_total_net_loss,
    COUNT(DISTINCT cra.c_customer_sk) AS num_customers
FROM customer_return_agg cra
JOIN catalog_returns cr   ON cr.cr_refunded_customer_sk = cra.c_customer_sk
JOIN catalog_page cp      ON cp.cp_catalog_page_sk    = cr.cr_catalog_page_sk
JOIN ship_mode sm         ON sm.sm_ship_mode_sk      = cr.cr_ship_mode_sk
JOIN warehouse w          ON w.w_warehouse_sk        = cr.cr_warehouse_sk
JOIN store_returns sr    ON sr.sr_customer_sk       = cra.c_customer_sk
JOIN store s              ON s.s_store_sk            = sr.sr_store_sk
WHERE cp.cp_description LIKE '%students%'
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'CA'
  AND s.s_gmt_offset = -5.00
  AND EXISTS (
        SELECT 1
        FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = cr.cr_ship_mode_sk
          AND sm2.sm_carrier = 'UPS'
      )
GROUP BY cp.cp_department, sm.sm_type, w.w_city, s.s_state
HAVING AVG(cra.total_net_loss) > 500
ORDER BY avg_total_net_loss DESC
LIMIT 100
