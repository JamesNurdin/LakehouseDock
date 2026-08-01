/*
  goal: Summarize net sales, return amounts and on‑hand inventory by catalog page, item category, warehouse state and the gender of the billing customer. The query joins all eleven selected TPC‑DS tables, re‑uses the CUSTOMER and CUSTOMER_ADDRESS tables with different aliases for billing and shipping roles, adds a web‑page join, uses a UNION DISTINCT of sales and returns, filters groups having more than $1,000 net paid, includes subtotal rows via GROUPING SETS, orders the result, and keeps only rows whose item participates in an active promotion (EXISTS sub‑query).
*/
WITH sales_data AS (
    SELECT
        cp_sales.cp_catalog_number            AS catalog_number,
        i.i_category                         AS item_category,
        wh_sales.w_state                     AS warehouse_state,
        cd_bill.cd_gender                    AS bill_gender,
        cs.cs_net_paid                       AS net_paid,
        CAST(0 AS decimal(7,2))              AS return_amount,
        inv.inv_quantity_on_hand             AS qty_on_hand,
        i.i_item_sk                          AS item_sk
    FROM catalog_sales cs
    JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN catalog_page cp_sales
        ON cs.cs_catalog_page_sk = cp_sales.cp_catalog_page_sk
    JOIN warehouse wh_sales
        ON cs.cs_warehouse_sk = wh_sales.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion promo_sales
        ON cs.cs_promo_sk = promo_sales.p_promo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = wh_sales.w_warehouse_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = cust_bill.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450900 AND 2451400
),
returns_data AS (
    SELECT
        cp_ret.cp_catalog_number            AS catalog_number,
        i_ret.i_category                    AS item_category,
        wh_ret.w_state                      AS warehouse_state,
        cd_ret.cd_gender                    AS bill_gender,
        CAST(0 AS decimal(7,2))            AS net_paid,
        cr.cr_return_amount                 AS return_amount,
        inv_ret.inv_quantity_on_hand        AS qty_on_hand,
        i_ret.i_item_sk                     AS item_sk
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp_ret
        ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    JOIN item i_ret
        ON cr.cr_item_sk = i_ret.i_item_sk
    JOIN warehouse wh_ret
        ON cr.cr_warehouse_sk = wh_ret.w_warehouse_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN inventory inv_ret
        ON inv_ret.inv_item_sk = i_ret.i_item_sk
       AND inv_ret.inv_warehouse_sk = wh_ret.w_warehouse_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450900 AND 2451400
)
SELECT
    catalog_number,
    item_category,
    warehouse_state,
    bill_gender,
    SUM(net_paid)        AS total_net_paid,
    SUM(return_amount)   AS total_return_amount,
    SUM(qty_on_hand)     AS total_qty_on_hand
FROM (
    SELECT * FROM sales_data
    UNION DISTINCT
    SELECT * FROM returns_data
) u
WHERE EXISTS (
    SELECT 1
    FROM promotion p
    WHERE p.p_item_sk = u.item_sk
      AND p.p_discount_active = 'Y'
)
GROUP BY GROUPING SETS (
    (catalog_number, item_category, warehouse_state, bill_gender),
    (catalog_number, item_category, warehouse_state),
    (catalog_number, item_category),
    (catalog_number),
    ()
)
HAVING SUM(net_paid) > 1000
ORDER BY catalog_number, item_category, warehouse_state, bill_gender
