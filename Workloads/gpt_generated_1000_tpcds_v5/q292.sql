/* goal: Identify the highest‑value catalog returns per store, enriched with web site and web page context, reason category, and average return amount for the same reason. The query joins all eight selected tables, applies four filters, uses a CASE expression, a scalar subquery, and a window function to rank returns within each store. */
WITH returns_enriched AS (
    SELECT
        cr.cr_order_number,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_reason_sk,
        cr.cr_item_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_addr_sk,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_paid,
        d_ret.d_date AS return_date,
        d_ret.d_quarter_name,
        ca_bill.ca_gmt_offset,
        wp.wp_autogen_flag,
        s.s_state,
        r.r_reason_desc,
        s.s_store_name,
        ws.web_name,
        wp.wp_web_page_id
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return
        ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_ship.d_date_sk
    WHERE d_ret.d_quarter_name = '1901Q3'
      AND ca_bill.ca_gmt_offset = -5.00
      AND wp.wp_autogen_flag = 'Y'
      AND s.s_state = 'CA'
      AND cs.cs_quantity > 5
)
SELECT
    re.s_store_name,
    re.web_name,
    re.return_date,
    re.cr_return_amount,
    CASE WHEN re.r_reason_desc = 'Customer Not Satisfied' THEN 'Dissatisfied' ELSE 'Other' END AS reason_category,
    (
        SELECT avg(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = re.cr_reason_sk
    ) AS avg_return_by_reason,
    ROW_NUMBER() OVER (PARTITION BY re.s_store_name ORDER BY re.cr_return_amount DESC) AS return_rank
FROM returns_enriched re
ORDER BY re.s_store_name, return_rank
LIMIT 100
