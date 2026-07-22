WITH
  cs AS (
    SELECT
      cs_order_number,
      cs_ext_sales_price,
      cs_sold_date_sk,
      cs_bill_customer_sk,
      cs_ship_customer_sk,
      cs_bill_cdemo_sk,
      cs_ship_cdemo_sk,
      cs_bill_addr_sk,
      cs_ship_addr_sk,
      cs_promo_sk
    FROM catalog_sales
  ),
  sr AS (
    SELECT
      sr_customer_sk,
      sr_cdemo_sk,
      sr_addr_sk,
      sr_reason_sk,
      sr_return_amt
    FROM store_returns
  ),
  wr AS (
    SELECT
      wr_refunded_customer_sk,
      wr_refunded_cdemo_sk,
      wr_refunded_addr_sk,
      wr_returning_customer_sk,
      wr_returning_cdemo_sk,
      wr_returning_addr_sk,
      wr_web_page_sk,
      wr_reason_sk,
      wr_return_amt
    FROM web_returns
  )
SELECT
  c_bill.c_customer_id,
  ca_bill.ca_city,
  cd_bill.cd_gender,
  p.p_promo_name,
  r_sr.r_reason_desc,
  wp.wp_type,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  SUM(sr.sr_return_amt) AS total_store_returns,
  SUM(wr.wr_return_amt) AS total_web_returns,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM cs
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c_bill
  ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
  ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN sr
  ON sr.sr_customer_sk = c_bill.c_customer_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN customer_address ca_sr
  ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN customer_demographics cd_sr
  ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN wr
  ON wr.wr_refunded_customer_sk = c_bill.c_customer_sk
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer c_page
  ON wp.wp_customer_sk = c_page.c_customer_sk
JOIN customer_address ca_wr_refunded
  ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
JOIN customer_address ca_wr_returning
  ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
JOIN customer_demographics cd_wr_refunded
  ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
JOIN customer_demographics cd_wr_returning
  ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
JOIN customer c_wr_refunded
  ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
JOIN customer c_wr_returning
  ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
GROUP BY
  c_bill.c_customer_id,
  ca_bill.ca_city,
  cd_bill.cd_gender,
  p.p_promo_name,
  r_sr.r_reason_desc,
  wp.wp_type
ORDER BY total_sales DESC
LIMIT 100
