WITH
  -- Store sales enriched with customer and address, plus two separate joins to store_returns
  sales_detail AS (
    SELECT
      ss.ss_sold_date_sk,
      c.c_customer_id,
      ca_ss.ca_state,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      CASE WHEN ss.ss_net_profit > 5000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag
    FROM store_sales ss
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca_ss
      ON ss.ss_addr_sk = ca_ss.ca_address_sk
    LEFT JOIN store_returns sr_ticket
      ON ss.ss_ticket_number = sr_ticket.sr_ticket_number
    LEFT JOIN store_returns sr_item
      ON ss.ss_item_sk = sr_item.sr_item_sk
  ),

  -- Store returns enriched with customer and address, plus two separate joins to store_sales
  returns_detail AS (
    SELECT
      sr.sr_returned_date_sk,
      c.c_customer_id,
      ca_sr.ca_state,
      sr.sr_return_amt,
      sr.sr_net_loss,
      CASE WHEN sr.sr_net_loss > 2000 THEN 'HIGH' ELSE 'LOW' END AS loss_flag
    FROM store_returns sr
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca_sr
      ON sr.sr_addr_sk = ca_sr.ca_address_sk
    LEFT JOIN store_sales ss_ticket
      ON sr.sr_ticket_number = ss_ticket.ss_ticket_number
    LEFT JOIN store_sales ss_item
      ON sr.sr_item_sk = ss_item.ss_item_sk
  ),

  -- Catalog sales enriched with billing/shipping customer/address and web page data
  catalog_detail AS (
    SELECT
      cs.cs_order_number,
      c.c_customer_id,
      ca_bill.ca_state   AS bill_state,
      ca_ship.ca_state   AS ship_state,
      cs.cs_ext_sales_price,
      cs.cs_net_paid,
      wp.wp_type,
      CASE WHEN cs.cs_ext_sales_price > 1000 THEN 'BIG' ELSE 'SMALL' END AS sale_size
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_address ca_curr
      ON c.c_current_addr_sk = ca_curr.ca_address_sk
  )

-- Combine the three analytical streams with UNION ALL
SELECT
  agg.customer_id,
  agg.state,
  SUM(agg.total_sales)   AS total_sales,
  SUM(agg.total_profit)  AS total_profit,
  SUM(agg.total_returns) AS total_returns,
  SUM(agg.total_loss)    AS total_loss,
  CASE
    WHEN SUM(agg.total_profit) - SUM(agg.total_loss) > 5000 THEN 'POSITIVE'
    ELSE 'NEGATIVE'
  END AS net_position
FROM (
  SELECT
    c_customer_id          AS customer_id,
    ca_state               AS state,
    ss_ext_sales_price     AS total_sales,
    ss_net_profit          AS total_profit,
    0.0                    AS total_returns,
    0.0                    AS total_loss
  FROM sales_detail

  UNION ALL

  SELECT
    c_customer_id          AS customer_id,
    ca_state               AS state,
    0.0                    AS total_sales,
    0.0                    AS total_profit,
    sr_return_amt          AS total_returns,
    sr_net_loss            AS total_loss
  FROM returns_detail

  UNION ALL

  SELECT
    c_customer_id          AS customer_id,
    bill_state             AS state,
    cs_ext_sales_price     AS total_sales,
    cs_net_paid            AS total_profit,
    0.0                    AS total_returns,
    0.0                    AS total_loss
  FROM catalog_detail
) agg
GROUP BY GROUPING SETS (
  (customer_id, state),
  ()
)
ORDER BY customer_id, state
