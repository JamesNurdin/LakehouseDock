WITH
  cs AS (
    SELECT cs_sold_date_sk,
           cs_ship_date_sk,
           cs_bill_customer_sk,
           cs_warehouse_sk,
           cs_item_sk,
           cs_promo_sk,
           cs_order_number,
           cs_net_profit,
           cs_call_center_sk
    FROM tpcds.catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  sr AS (
    SELECT sr_returned_date_sk,
           sr_item_sk,
           sr_customer_sk,
           sr_ticket_number,
           sr_return_amt,
           sr_net_loss
    FROM tpcds.store_returns
  ),
  d_sold AS (
    SELECT d_date_sk, d_year
    FROM tpcds.date_dim
    WHERE d_year = 2001
  ),
  d_return AS (
    SELECT d_date_sk, d_year
    FROM tpcds.date_dim
    WHERE d_year = 2001
  ),
  cust AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag
    FROM tpcds.customer
    WHERE c_preferred_cust_flag = 'Y'
  ),
  cc AS (
    SELECT cc_call_center_sk, cc_name, cc_state
    FROM tpcds.call_center
    WHERE cc_state = 'CA'
  ),
  wh AS (
    SELECT w_warehouse_sk, w_warehouse_name, w_state
    FROM tpcds.warehouse
    WHERE w_state = 'CA'
  ),
  itm AS (
    SELECT i_item_sk, i_brand, i_product_name
    FROM tpcds.item
    WHERE i_brand = 'Brand#12'
  ),
  itm2 AS (
    SELECT i_item_sk, i_brand
    FROM tpcds.item
    WHERE i_units = 'Tsp'
  ),
  promo AS (
    SELECT p_promo_sk, p_promo_name, p_start_date_sk
    FROM tpcds.promotion
    WHERE p_purpose = 'Unknown'
  ),
  wp AS (
    SELECT wp_web_page_sk, wp_url, wp_customer_sk, wp_max_ad_count
    FROM tpcds.web_page
    WHERE wp_type = 'Content'
  ),
  scalar_max_profit AS (
    SELECT max(cs_net_profit) AS max_profit
    FROM tpcds.catalog_sales
    WHERE cs_sold_date_sk = 2450600
  ),
  cs_cc_full AS (
    SELECT
      cs.cs_order_number      AS order_number,
      cs.cs_sold_date_sk,
      cs.cs_net_profit,
      cs.cs_bill_customer_sk,
      cs.cs_warehouse_sk,
      cs.cs_item_sk,
      cs.cs_promo_sk,
      cc.cc_name
    FROM cs
    FULL OUTER JOIN cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  ),
  union_set AS (
    SELECT
      csf.order_number                     AS order_id,
      c.c_customer_sk,
      d_sold.d_year,
      itm.i_brand,
      csf.cc_name,
      wh.w_warehouse_name,
      csf.cs_net_profit
    FROM cs_cc_full csf
    JOIN d_sold   ON csf.cs_sold_date_sk   = d_sold.d_date_sk
    JOIN cust c   ON csf.cs_bill_customer_sk = c.c_customer_sk
    JOIN wh       ON csf.cs_warehouse_sk   = wh.w_warehouse_sk
    JOIN itm      ON csf.cs_item_sk        = itm.i_item_sk
    JOIN promo    ON csf.cs_promo_sk       = promo.p_promo_sk
    WHERE csf.cs_net_profit > (SELECT max_profit FROM scalar_max_profit)

    UNION DISTINCT

    SELECT
      sr.sr_ticket_number AS order_id,
      c2.c_customer_sk,
      d_return.d_year,
      itm2.i_brand,
      NULL AS cc_name,
      NULL AS w_warehouse_name,
      -sr.sr_net_loss AS cs_net_profit
    FROM sr
    JOIN d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN cust c2   ON sr.sr_customer_sk = c2.c_customer_sk
    JOIN itm2      ON sr.sr_item_sk = itm2.i_item_sk
    LEFT JOIN wp    ON c2.c_customer_sk = wp.wp_customer_sk
  ),
  except_set AS (
    SELECT order_id, c_customer_sk, d_year, i_brand, cc_name, w_warehouse_name, cs_net_profit
    FROM union_set
    EXCEPT
    SELECT u.order_id, u.c_customer_sk, u.d_year, u.i_brand, u.cc_name, u.w_warehouse_name, u.cs_net_profit
    FROM union_set u
    JOIN wp ON u.c_customer_sk = wp.wp_customer_sk
    WHERE wp.wp_max_ad_count = 0
  ),
  high_profit_orders AS (
    SELECT cs_order_number AS order_id FROM tpcds.catalog_sales WHERE cs_net_profit > 0
  ),
  low_loss_orders AS (
    SELECT sr_ticket_number AS order_id FROM tpcds.store_returns WHERE sr_net_loss < 1000
  ),
  common_orders AS (
    SELECT order_id FROM high_profit_orders
    INTERSECT
    SELECT order_id FROM low_loss_orders
  )
SELECT
  es.order_id,
  es.c_customer_sk,
  es.d_year,
  es.i_brand,
  es.cc_name,
  es.w_warehouse_name,
  SUM(es.cs_net_profit) AS total_profit
FROM except_set es
JOIN common_orders co ON es.order_id = co.order_id
GROUP BY
  es.order_id,
  es.c_customer_sk,
  es.d_year,
  es.i_brand,
  es.cc_name,
  es.w_warehouse_name
ORDER BY total_profit DESC
LIMIT 100
