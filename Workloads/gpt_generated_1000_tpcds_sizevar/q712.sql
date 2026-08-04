WITH
  base_sales AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_addr_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      i.i_item_sk,
      i.i_item_id,
      i.i_category,
      ca.ca_state
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_quantity > 1
      AND ss.ss_ext_sales_price > 100
      AND ss.ss_net_profit > 0
      AND ss.ss_sold_date_sk BETWEEN 2450800 AND 2450900
      AND i.i_current_price < 1000
  ),
  catalog_facts AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_ext_sales_price,
      cs.cs_quantity,
      cs.cs_net_paid,
      i.i_item_sk,
      i.i_category,
      ca.ca_state AS bill_state
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_quantity >= 2
      AND cs.cs_ext_sales_price > 500
      AND cs.cs_net_paid > 0
      AND cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
      AND i.i_current_price < 1500
  ),
  catalog_returns_facts AS (
    SELECT
      cr.cr_order_number,
      cr.cr_item_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      i.i_item_sk,
      i.i_category
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 0
  ),
  store_returns_facts AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_item_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      i.i_item_sk,
      i.i_category
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_return_quantity > 0
  ),
  order_numbers_sales AS (
    SELECT ss_ticket_number FROM store_sales
  ),
  order_numbers_returns AS (
    SELECT sr_ticket_number FROM store_returns
  ),
  sales_minus_returns AS (
    SELECT ss_ticket_number FROM order_numbers_sales
    EXCEPT
    SELECT sr_ticket_number FROM order_numbers_returns
  ),
  intersect_order_numbers AS (
    SELECT cr_order_number FROM catalog_returns
    INTERSECT
    SELECT cs_order_number FROM catalog_sales
  )
SELECT
  bs.ss_ticket_number,
  bs.ss_sold_date_sk,
  bs.i_item_id,
  bs.i_category,
  bs.ca_state,
  bs.ss_ext_sales_price,
  bs.ss_net_profit,
  RANK() OVER (PARTITION BY bs.i_category ORDER BY bs.ss_net_profit DESC) AS profit_rank,
  CASE WHEN srF.sr_ticket_number IS NULL THEN 'No Store Return' ELSE 'Store Return' END AS store_return_flag,
  CASE WHEN crF.cr_order_number IS NULL THEN 'No Catalog Return' ELSE 'Catalog Return' END AS catalog_return_flag,
  cf.cs_ext_sales_price AS catalog_sales_price,
  cf.cs_quantity AS catalog_quantity
FROM base_sales bs
LEFT JOIN store_returns_facts srF
  ON bs.ss_ticket_number = srF.sr_ticket_number
LEFT JOIN catalog_returns_facts crF
  ON bs.ss_ticket_number = crF.cr_order_number
FULL OUTER JOIN catalog_facts cf
  ON bs.i_item_sk = cf.i_item_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = bs.ss_ticket_number
          AND sr.sr_return_quantity > 5
      )
  AND bs.ss_ticket_number IN (SELECT ss_ticket_number FROM sales_minus_returns)
  AND bs.ss_ticket_number IN (SELECT cr_order_number FROM intersect_order_numbers)
ORDER BY profit_rank, bs.ss_ticket_number
LIMIT 100
