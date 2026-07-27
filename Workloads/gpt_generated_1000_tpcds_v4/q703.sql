WITH cust AS (
   SELECT c_customer_sk,
          c_customer_id,
          c_first_name,
          c_last_name
   FROM   customer
   WHERE  c_birth_year BETWEEN 1960 AND 1970
),
cs AS (
   SELECT cs_order_number,
          cs_bill_customer_sk,
          cs_ship_customer_sk,
          cs_ext_sales_price
   FROM   catalog_sales
   WHERE  cs_ship_date_sk = 2450906
),
ss AS (
   SELECT ss_ticket_number,
          ss_customer_sk,
          ss_item_sk,
          ss_ext_sales_price
   FROM   store_sales
   WHERE  ss_quantity > 1
),
sr AS (
   SELECT sr_ticket_number,
          sr_customer_sk,
          sr_item_sk,
          sr_return_amt
   FROM   store_returns
   WHERE  sr_return_quantity > 0
),
wr AS (
   SELECT wr_order_number,
          wr_refunded_customer_sk,
          wr_returning_customer_sk,
          wr_web_page_sk,
          wr_return_amt
   FROM   web_returns
   WHERE  wr_return_quantity > 0
),
wp AS (
   SELECT wp_web_page_sk,
          wp_customer_sk,
          wp_char_count,
          wp_image_count
   FROM   web_page
   WHERE  wp_type = 'product'
)
SELECT
   cust_main.c_customer_id,
   cust_main.c_first_name,
   cust_main.c_last_name,
   SUM(cs.cs_ext_sales_price)          AS total_catalog_sales,
   SUM(ss_item.ss_ext_sales_price)     AS total_store_sales,
   SUM(sr.sr_return_amt)               AS total_store_returns,
   SUM(wr.wr_return_amt)               AS total_web_returns,
   COUNT(DISTINCT cs.cs_order_number)  AS catalog_orders,
   COUNT(DISTINCT ss_ticket.ss_ticket_number) AS store_tickets
FROM   cust AS cust_main
-- catalog_sales joins (two different customer roles)
JOIN   cs                               ON cs.cs_bill_customer_sk = cust_main.c_customer_sk
JOIN   cust AS cust_ship                ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
-- store_sales joins (item perspective and ticket perspective)
JOIN   ss AS ss_item                    ON ss_item.ss_customer_sk = cust_main.c_customer_sk
JOIN   sr                               ON sr.sr_customer_sk = cust_main.c_customer_sk
JOIN   ss AS ss_ticket                  ON ss_ticket.ss_ticket_number = sr.sr_ticket_number
JOIN   cust AS cust_sr                  ON sr.sr_customer_sk = cust_sr.c_customer_sk
-- web_returns and web_page joins (refunded, returning and page owner)
JOIN   wr                               ON wr.wr_refunded_customer_sk = cust_main.c_customer_sk
JOIN   cust AS cust_returning          ON wr.wr_returning_customer_sk = cust_returning.c_customer_sk
JOIN   wp                               ON wp.wp_web_page_sk = wr.wr_web_page_sk
JOIN   cust AS cust_wp                  ON wp.wp_customer_sk = cust_wp.c_customer_sk
GROUP BY
   cust_main.c_customer_id,
   cust_main.c_first_name,
   cust_main.c_last_name
ORDER BY total_catalog_sales DESC
LIMIT 100
