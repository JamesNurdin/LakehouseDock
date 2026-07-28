WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_sold_date_sk,
    cp.cp_department,
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    sm.sm_type,
    p.p_promo_name,
    ss.ss_quantity,
    ws.ws_quantity AS ws_quantity,
    sr.sr_return_quantity
  FROM tpcds.catalog_sales cs
  JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN tpcds.customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN tpcds.store_sales ss
    ON i.i_item_sk = ss.ss_item_sk
  LEFT JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  JOIN tpcds.web_sales ws
    ON i.i_item_sk = ws.ws_item_sk
   AND ws.ws_bill_addr_sk = ca_bill.ca_address_sk
 WHERE cp.cp_department = 'Electronics'
   AND i.i_units = 'Dozen'
   AND w.w_state = 'CA'
   AND NOT EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr2
        WHERE sr2.sr_ticket_number = ss.ss_ticket_number
          AND sr2.sr_item_sk = ss.ss_item_sk
   )
)
SELECT DISTINCT
  base.cs_order_number,
  base.cs_net_paid,
  base.cp_department,
  base.i_item_id,
  base.i_product_name,
  base.w_warehouse_name,
  base.sm_type,
  base.p_promo_name,
  ROW_NUMBER() OVER (PARTITION BY base.cp_department ORDER BY base.cs_net_paid DESC) AS dept_sales_rank,
  SUM(base.cs_net_paid) OVER (
        PARTITION BY base.cp_department
        ORDER BY base.cs_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_dept_sales
FROM base
ORDER BY dept_sales_rank, base.cs_net_paid DESC
LIMIT 100
