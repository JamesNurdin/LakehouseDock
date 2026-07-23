WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ca.ca_address_sk,
        ca.ca_state,
        ca.ca_country
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
)
SELECT
    r_store.r_reason_desc AS store_return_reason,
    sb.ca_state AS sales_state,
    SUM(sr.sr_net_loss) AS total_store_return_net_loss,
    SUM(cr.cr_net_loss) AS total_catalog_return_net_loss,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
    CASE
        WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High'
        WHEN SUM(ws.ws_net_profit) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS web_profit_category,
    SUM(CASE WHEN cr.cr_fee > 50 THEN cr.cr_fee ELSE 0 END) AS high_fee_total
FROM sales_base sb
JOIN store_returns sr
    ON sr.sr_item_sk = sb.ss_item_sk
    AND sr.sr_ticket_number = sb.ss_ticket_number
JOIN reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN customer_address ca_return
    ON sr.sr_addr_sk = ca_return.ca_address_sk
JOIN catalog_returns cr
    ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
JOIN reason r_cat
    ON cr.cr_reason_sk = r_cat.r_reason_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN web_sales ws
    ON ws.ws_bill_addr_sk = sb.ca_address_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
WHERE cr.cr_fee > 20
GROUP BY r_store.r_reason_desc, sb.ca_state
ORDER BY total_store_return_net_loss DESC
LIMIT 100
