/*
Goal: Analyze combined sales, returns, and inventory performance by customer and item, comparing catalog and web channels, while retaining unmatched rows from catalog returns (FULL OUTER JOIN), all web pages (RIGHT OUTER JOIN), and all customers (RIGHT OUTER JOIN). The query also demonstrates set intersection of order numbers across channels and uses a semi‑join to filter customers with return activity.
*/
WITH
order_intersection AS (
    SELECT cs_order_number AS order_num
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2451080 AND 2451085
    INTERSECT
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451080 AND 2451085
),
filtered_items AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           i.i_current_price
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 500
      AND inv.inv_warehouse_sk = 8
      AND i.i_current_price BETWEEN 10 AND 100
),
full_cr_cs AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk
    FROM catalog_returns cr
    FULL OUTER JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
),
full_returns AS (
    SELECT
        COALESCE(sr.sr_item_sk, wr.wr_item_sk) AS item_sk,
        sr.sr_return_amt                AS store_return_amt,
        wr.wr_return_amt                AS web_return_amt
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr
        ON sr.sr_item_sk = wr.wr_item_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_income_band_sk,
    i.i_item_id,
    i.i_product_name,
    SUM(fcs.cs_net_paid)               AS total_sales,
    SUM(ws.ws_net_paid_inc_ship_tax)   AS total_web_sales,
    SUM(fr.store_return_amt)           AS total_store_returns,
    SUM(fr.web_return_amt)             AS total_web_returns,
    COUNT(DISTINCT fcs.cs_order_number) AS distinct_orders,
    AVG(inv.inv_quantity_on_hand)      AS avg_inventory_qty,
    MIN(fcs.cs_sold_date_sk)           AS earliest_sale_date_sk,
    MAX(fcs.cs_sold_date_sk)           AS latest_sale_date_sk
FROM filtered_items i
LEFT JOIN full_cr_cs fcs
    ON fcs.cs_item_sk = i.i_item_sk
RIGHT OUTER JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
RIGHT OUTER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
RIGHT OUTER JOIN customer c
    ON fcs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON fcs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON fcs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON fcs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN full_returns fr
    ON fr.item_sk = i.i_item_sk
WHERE c.c_birth_year = 1985
  AND wp.wp_link_count >= 5
  AND ws.ws_net_paid_inc_ship_tax > 2000.00
  AND fcs.cs_sold_date_sk BETWEEN 2451080 AND 2451085
  AND fcs.cs_order_number IN (SELECT order_num FROM order_intersection)
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
          AND cr2.cr_return_amount > 0
    )
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_income_band_sk,
    i.i_item_id,
    i.i_product_name
ORDER BY total_sales DESC
LIMIT 100
