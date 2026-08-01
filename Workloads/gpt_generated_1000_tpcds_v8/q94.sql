WITH
  cs AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_ship_date_sk,
      cs.cs_item_sk,
      cs.cs_promo_sk,
      cs.cs_bill_customer_sk,
      cs.cs_ship_customer_sk,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_paid,
      cs.cs_net_profit,
      d_sold.d_year AS sold_year,
      d_ship.d_month_seq AS ship_month_seq,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      cd_bill.cd_gender AS bill_gender,
      cd_ship.cd_gender AS ship_gender,
      ca_bill.ca_state AS bill_state,
      ca_ship.ca_state AS ship_state,
      c_bill.c_customer_id AS bill_customer_id,
      c_ship.c_customer_id AS ship_customer_id
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c_bill
      ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
      ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
      ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  ),
  sr AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_item_sk,
      sr.sr_customer_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      d_sr.d_year AS return_year,
      i_sr.i_category,
      r.r_reason_desc,
      cd_sr.cd_gender AS return_demo_gender,
      ca_sr.ca_state AS return_state
    FROM store_returns sr
    JOIN date_dim d_sr
      ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN item i_sr
      ON sr.sr_item_sk = i_sr.i_item_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_sr
      ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN customer_address ca_sr
      ON sr.sr_addr_sk = ca_sr.ca_address_sk
  ),
  wr AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_refunded_customer_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      d_wr.d_year AS web_return_year,
      i_wr.i_category,
      r_wr.r_reason_desc,
      cd_ref.cd_gender AS refunded_demo_gender,
      ca_ref.ca_state AS refunded_state,
      cd_ret.cd_gender AS returning_demo_gender,
      ca_ret.ca_state AS returning_state
    FROM web_returns wr
    JOIN date_dim d_wr
      ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN item i_wr
      ON wr.wr_item_sk = i_wr.i_item_sk
    JOIN reason r_wr
      ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN customer_demographics cd_ref
      ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_address ca_ref
      ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_demographics cd_ret
      ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN customer_address ca_ret
      ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
  ),
  inv AS (
    SELECT
      inv.inv_date_sk,
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      d_inv.d_year AS inv_year,
      i_inv.i_category
    FROM inventory inv
    JOIN date_dim d_inv
      ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN item i_inv
      ON inv.inv_item_sk = i_inv.i_item_sk
  )
SELECT
  cs.sold_year,
  cs.i_category,
  cs.i_brand,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  SUM(cs.cs_net_profit) AS total_profit,
  COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_return,
  COALESCE(SUM(wr.wr_return_amt), 0) AS total_web_return,
  COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_on_hand,
  RANK() OVER (PARTITION BY cs.sold_year ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank_by_year
FROM cs
LEFT JOIN sr
  ON cs.cs_item_sk = sr.sr_item_sk
  AND cs.sold_year = sr.return_year
LEFT JOIN wr
  ON cs.cs_item_sk = wr.wr_item_sk
  AND cs.sold_year = wr.web_return_year
LEFT JOIN inv
  ON cs.cs_item_sk = inv.inv_item_sk
  AND cs.sold_year = inv.inv_year
GROUP BY
  cs.sold_year,
  cs.i_category,
  cs.i_brand
ORDER BY
  cs.sold_year DESC,
  total_sales DESC
LIMIT 100
