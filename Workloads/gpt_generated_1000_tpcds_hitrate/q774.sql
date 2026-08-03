WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_paid_inc_ship,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_item_sk,
    cs.cs_ship_customer_sk,
    cs.cs_bill_customer_sk,
    cs.cs_ship_hdemo_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_ship_addr_sk,
    cs.cs_bill_addr_sk,
    cs.cs_ship_mode_sk,
    cs.cs_warehouse_sk,
    cs.cs_catalog_page_sk,
    i.i_item_sk,
    i.i_category,
    i.i_brand,
    c_bill.c_customer_sk AS bill_cust_sk,
    c_ship.c_customer_sk AS ship_cust_sk,
    hd_bill.hd_demo_sk AS bill_hdemo_sk,
    hd_ship.hd_demo_sk AS ship_hdemo_sk,
    ca_bill.ca_address_sk AS bill_addr_sk,
    ca_ship.ca_address_sk AS ship_addr_sk,
    sm.sm_ship_mode_sk,
    w.w_warehouse_sk,
    cp.cp_catalog_page_sk
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
),
joined AS (
  SELECT
    CASE
      WHEN i_category = 'Electronics' THEN 'ELEC'
      WHEN i_category = 'Furniture'  THEN 'FURN'
      ELSE 'OTHER'
    END AS grp,
    b.cs_net_paid_inc_ship AS net_paid,
    b.cs_order_number AS order_num,
    ss.ss_ticket_number,
    ws.ws_order_number,
    cr.cr_return_quantity,
    inv.inv_quantity_on_hand,
    c_ship.c_customer_id AS ship_cust_id,
    c_bill.c_customer_id AS bill_cust_id
  FROM base b
  JOIN store_sales ss ON ss.ss_item_sk = b.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN web_sales ws ON ws.ws_item_sk = b.i_item_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  JOIN catalog_returns cr ON cr.cr_order_number = b.cs_order_number
  JOIN inventory inv ON inv.inv_item_sk = b.i_item_sk AND inv.inv_warehouse_sk = b.w_warehouse_sk
  JOIN customer c_ship ON b.cs_ship_customer_sk = c_ship.c_customer_sk
  JOIN customer c_bill ON b.cs_bill_customer_sk = c_bill.c_customer_sk
  WHERE b.cs_sold_date_sk BETWEEN 2450000 AND 2451000
)
SELECT
  grp,
  SUM(net_paid) AS total_net_paid,
  COUNT(DISTINCT order_num) AS orders_cnt,
  CASE WHEN SUM(net_paid) > 20000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category,
  ROW_NUMBER() OVER (PARTITION BY grp ORDER BY SUM(net_paid) DESC) AS rn
FROM joined
WHERE order_num NOT IN (
  SELECT cr2.cr_order_number
  FROM catalog_returns cr2
  WHERE cr2.cr_return_quantity > 10
)
GROUP BY GROUPING SETS ( (grp), () )
HAVING SUM(net_paid) > 0
ORDER BY total_net_paid DESC
LIMIT 100
