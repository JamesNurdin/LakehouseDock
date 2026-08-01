WITH customer_union AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk FROM catalog_sales cs
    UNION
    SELECT ws.ws_bill_customer_sk AS customer_sk FROM web_sales ws
),
avg_discount AS (
    SELECT avg(cs.cs_ext_discount_amt) AS avg_disc FROM catalog_sales cs
)
SELECT
    d_sold.d_year,
    wh.w_state,
    cp.cp_department,
    ws_site.web_name,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS catalog_net_paid,
    SUM(ss.ss_net_paid) AS store_net_paid,
    SUM(ws.ws_net_paid) AS web_net_paid,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
    MIN(cs.cs_ext_discount_amt) AS min_discount,
    MAX(cs.cs_ext_discount_amt) AS max_discount
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse wh
    ON cs.cs_warehouse_sk = wh.w_warehouse_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
   AND inv.inv_warehouse_sk = wh.w_warehouse_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE d_sold.d_year = 2001
  AND cp.cp_department = 'Books'
  AND sm.sm_type = 'AIR'
  AND wh.w_state = 'CA'
  AND ca.ca_country = 'United States'
  AND ws_site.web_name LIKE '%Online%'
  AND inv.inv_quantity_on_hand > 500
  AND cs.cs_ext_discount_amt > (SELECT avg_disc FROM avg_discount)
  AND EXISTS (SELECT 1 FROM customer_union cu WHERE cu.customer_sk = cs.cs_bill_customer_sk)
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
    )
GROUP BY d_sold.d_year, wh.w_state, cp.cp_department, ws_site.web_name
ORDER BY d_sold.d_year, wh.w_state, catalog_net_paid DESC
LIMIT 100
