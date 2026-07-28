/*
Goal: Identify the top customers by net revenue across catalog, store, and web sales for the year 2001, considering only active promotions, warehouses in CA, and items that had inventory on hand. The query ranks each customer's transactions and returns distinct rows with relevant dimension attributes.
*/
WITH inv_filter AS (
    SELECT inv.inv_warehouse_sk,
           inv.inv_date_sk
    FROM   inventory inv
    WHERE  inv.inv_quantity_on_hand > 0
)
SELECT DISTINCT
    d.d_year,
    cust.c_customer_id,
    ca.ca_state,
    hd.hd_buy_potential,
    p.p_promo_name,
    w.w_warehouse_name,
    ws_site.web_name,
    cs.cs_order_number,
    ss.ss_ticket_number,
    ws.ws_order_number,
    (COALESCE(cs.cs_net_paid, 0) +
     COALESCE(ss.ss_net_paid, 0) +
     COALESCE(ws.ws_net_paid, 0) -
     COALESCE(cr.cr_return_amount, 0)) AS total_net,
    ROW_NUMBER() OVER (
        PARTITION BY cust.c_customer_id
        ORDER BY (COALESCE(cs.cs_net_paid, 0) +
                  COALESCE(ss.ss_net_paid, 0) +
                  COALESCE(ws.ws_net_paid, 0) -
                  COALESCE(cr.cr_return_amount, 0)) DESC
    ) AS purchase_rank
FROM   catalog_sales cs
JOIN   catalog_returns cr
       ON cr.cr_order_number = cs.cs_order_number
JOIN   customer cust
       ON cust.c_customer_sk = cs.cs_bill_customer_sk
JOIN   household_demographics hd
       ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN   customer_address ca
       ON ca.ca_address_sk = cs.cs_bill_addr_sk
JOIN   promotion p
       ON p.p_promo_sk = cs.cs_promo_sk
JOIN   warehouse w
       ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN   date_dim d
       ON d.d_date_sk = cs.cs_sold_date_sk
JOIN   web_sales ws
       ON ws.ws_bill_customer_sk = cust.c_customer_sk
      AND ws.ws_sold_date_sk = d.d_date_sk
JOIN   web_site ws_site
       ON ws_site.web_site_sk = ws.ws_web_site_sk
LEFT JOIN store_sales ss
       ON ss.ss_customer_sk = cust.c_customer_sk
      AND ss.ss_sold_date_sk = d.d_date_sk
WHERE  EXISTS (
           SELECT 1
           FROM   inv_filter i
           WHERE  i.inv_warehouse_sk = cs.cs_warehouse_sk
           AND    i.inv_date_sk = cs.cs_sold_date_sk
       )
  AND d.d_year = 2001
  AND p.p_discount_active = 'Y'
  AND w.w_state = 'CA'
ORDER BY total_net DESC
LIMIT 100
