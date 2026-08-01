WITH sales_detail AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        cp.cp_description,
        w.w_warehouse_name,
        i.i_product_name,
        i2.i_category AS item_category,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_ext_sales_price DESC) AS rn
    FROM catalog_sales cs
    LEFT JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN item i2
        ON cs.cs_item_sk = i2.i_item_sk
    WHERE cp.cp_description LIKE '%Economic%'
),
returns_detail AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_addr_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt,
        ca_ret.ca_state AS return_state,
        i_ret.i_product_name,
        r.r_reason_desc
    FROM store_returns sr
    JOIN customer_address ca_ret
        ON sr.sr_addr_sk = ca_ret.ca_address_sk
    JOIN item i_ret
        ON sr.sr_item_sk = i_ret.i_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
),
 ticket_set_a AS (
    SELECT sr_ticket_number FROM store_returns WHERE sr_return_amt > 500
),
 ticket_set_b AS (
    SELECT cs_order_number FROM catalog_sales WHERE cs_ext_sales_price > 1000
),
 high_return_tickets AS (
    SELECT sr_ticket_number FROM store_returns WHERE sr_return_amt > 1000
),
 high_sales_orders AS (
    SELECT cs_order_number FROM catalog_sales WHERE cs_ext_sales_price > 5000
),
 except_set AS (
    SELECT sr_ticket_number FROM high_return_tickets
    EXCEPT
    SELECT cs_order_number FROM high_sales_orders
)
SELECT
    sd.cs_order_number,
    sd.i_product_name,
    sd.cp_description,
    sd.w_warehouse_name,
    sd.item_category,
    sd.rn,
    (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = sd.cs_item_sk
    ) AS total_return_amount,
    CASE WHEN sd.rn = 1 THEN 'Top' ELSE 'Other' END AS rank_category
FROM sales_detail sd
RIGHT OUTER JOIN item i_unmatched
    ON sd.cs_item_sk = i_unmatched.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr3
    WHERE sr3.sr_item_sk = sd.cs_item_sk
      AND sr3.sr_return_amt > 200
)
  AND sd.cs_order_number IN (
        SELECT ticket FROM (
            SELECT sr_ticket_number AS ticket FROM ticket_set_a
            UNION ALL
            SELECT cs_order_number AS ticket FROM ticket_set_b
        )
    )
  AND sd.cs_order_number IN (
        SELECT ticket FROM (
            SELECT sr_ticket_number AS ticket FROM high_return_tickets
            INTERSECT
            SELECT cs_order_number AS ticket FROM high_sales_orders
        )
    )
  AND sd.cs_order_number NOT IN (SELECT sr_ticket_number FROM except_set)
ORDER BY sd.cs_net_profit DESC
LIMIT 100
