WITH agg AS (
  SELECT
    i.i_category AS category,
    c_bill.c_salutation AS salutation,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    CASE
      WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit'
      ELSE 'Loss'
    END AS profit_flag
  FROM tpcds.catalog_sales cs
  JOIN tpcds.customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN tpcds.household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN tpcds.customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  JOIN tpcds.customer c_refund
    ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
  JOIN tpcds.household_demographics hd_refund
    ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
  JOIN tpcds.customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
  JOIN tpcds.store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN tpcds.customer c_store
    ON sr.sr_customer_sk = c_store.c_customer_sk
  JOIN tpcds.household_demographics hd_store
    ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
  JOIN tpcds.customer_address ca_store
    ON sr.sr_addr_sk = ca_store.ca_address_sk
  JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN tpcds.web_page wp
    ON wp.wp_customer_sk = c_bill.c_customer_sk
  WHERE c_bill.c_birth_year BETWEEN 1950 AND 2000
  GROUP BY i.i_category, c_bill.c_salutation
  HAVING SUM(cs.cs_net_profit) > 1000
)
SELECT
  category,
  salutation,
  total_catalog_net_profit,
  total_catalog_returns_loss,
  total_store_returns_loss,
  total_inventory_on_hand,
  profit_flag,
  ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_catalog_net_profit DESC) AS category_rank
FROM agg
ORDER BY total_catalog_net_profit DESC
LIMIT 100
