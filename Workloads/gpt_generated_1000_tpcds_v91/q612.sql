SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca_store.ca_state AS store_state,
    p_store.p_promo_name AS sale_promo_name,
    r_store.r_reason_desc AS store_return_reason,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_net_paid) AS total_sales_amount,
    SUM(sr.sr_net_loss) AS total_return_loss,
    CASE 
        WHEN SUM(ss.ss_net_paid) - SUM(sr.sr_net_loss) > 0 THEN 'Net Gain'
        ELSE 'Net Loss or Break-even'
    END AS net_status
FROM store_sales ss
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca_store
    ON ss.ss_addr_sk = ca_store.ca_address_sk
JOIN promotion p_store
    ON ss.ss_promo_sk = p_store.p_promo_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN promotion p_catalog
    ON cs.cs_promo_sk = p_catalog.p_promo_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN reason r_web
    ON wr.wr_reason_sk = r_web.r_reason_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr_sub
    WHERE wr_sub.wr_item_sk = ss.ss_item_sk
      AND wr_sub.wr_refunded_customer_sk = c.c_customer_sk
)
GROUP BY
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca_store.ca_state,
    p_store.p_promo_name,
    r_store.r_reason_desc
ORDER BY net_status DESC, total_sales_amount DESC
LIMIT 100
