WITH
    avg_price AS (
        SELECT AVG(i2.i_current_price) AS avg_price
        FROM item i2
        WHERE i2.i_brand_id = 10
    ),
    cs_base AS (
        SELECT cs.cs_sold_date_sk,
               cs.cs_order_number,
               cs.cs_quantity,
               cs.cs_net_paid,
               cs.cs_ext_discount_amt,
               cs.cs_item_sk,
               cs.cs_warehouse_sk,
               cs.cs_bill_addr_sk,
               cs.cs_ship_addr_sk,
               cs.cs_ship_date_sk,
               cs.cs_bill_customer_sk,
               cs.cs_ship_customer_sk
        FROM catalog_sales cs
        WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450948        -- filter on surrogate date key
          AND cs.cs_quantity > 1                                 -- filter on quantity
          AND cs.cs_ext_discount_amt > 100.00                   -- filter on discount amount
    )
SELECT
    cs.cs_order_number,
    i.i_item_id,
    w.w_warehouse_name,
    ca_bill.ca_state               AS bill_state,
    ca_ship.ca_state               AS ship_state,
    SUM(cs.cs_net_paid)            AS total_net_paid,
    AVG(ws.ws_ext_discount_amt)    AS avg_web_discount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT i.i_item_id)    AS distinct_items,
    MIN(cs.cs_quantity)            AS min_quantity,
    MAX(cs.cs_quantity)            AS max_quantity,
    CASE
        WHEN cr.cr_return_amount > 100 THEN 'High'
        ELSE 'Low'
    END                            AS return_category,
    avg_price.avg_price            AS avg_price_brand_10
FROM cs_base cs
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk,
    avg_price
WHERE i.i_category = 'Electronics'                     -- filter on item category
  AND w.w_state = 'CA'                                   -- filter on warehouse state
  AND cs.cs_order_number NOT IN (
        SELECT ws2.ws_order_number
        FROM web_sales ws2
        WHERE ws2.ws_quantity > 500
    )                                                   -- anti‑semi‑join filter
GROUP BY
    cs.cs_order_number,
    i.i_item_id,
    w.w_warehouse_name,
    ca_bill.ca_state,
    ca_ship.ca_state,
    CASE
        WHEN cr.cr_return_amount > 100 THEN 'High'
        ELSE 'Low'
    END,
    avg_price.avg_price
ORDER BY total_net_paid DESC
LIMIT 100
