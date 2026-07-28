WITH
  high_returns AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_reason_sk,
      cr.cr_order_number,
      cr.cr_item_sk,
      cs.cs_net_paid_inc_ship,
      i.i_item_desc,
      r.r_reason_desc,
      ROW_NUMBER() OVER (PARTITION BY cr.cr_reason_sk ORDER BY cr.cr_return_amount DESC) AS rn
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN item i2
      ON cs.cs_item_sk = i2.i_item_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN customer_address ca_refunded
      ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN customer_address ca_returning
      ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    LEFT JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN customer_address ca_bill2
      ON cs.cs_bill_addr_sk = ca_bill2.ca_address_sk
    WHERE cr.cr_return_amount > 100
  ),
  low_returns AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_reason_sk,
      cr.cr_order_number,
      cr.cr_item_sk,
      cs.cs_net_paid_inc_ship,
      i.i_item_desc,
      r.r_reason_desc,
      ROW_NUMBER() OVER (PARTITION BY cr.cr_reason_sk ORDER BY cr.cr_return_amount ASC) AS rn
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN item i2
      ON cs.cs_item_sk = i2.i_item_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN customer_address ca_refunded
      ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN customer_address ca_returning
      ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    LEFT JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN customer_address ca_bill2
      ON cs.cs_bill_addr_sk = ca_bill2.ca_address_sk
    WHERE cr.cr_return_amount <= 100
  )
SELECT
  rs.r_reason_desc,
  COUNT(*) AS total_returns,
  SUM(rs.cr_return_amount) AS sum_return_amount,
  AVG(rs.cr_return_amount) AS avg_return_amount,
  SUM(rs.cs_net_paid_inc_ship) AS sum_net_paid_inc_ship
FROM (
  SELECT * FROM high_returns
  UNION ALL
  SELECT * FROM low_returns
) rs
GROUP BY rs.r_reason_desc
ORDER BY sum_return_amount DESC
LIMIT 10
