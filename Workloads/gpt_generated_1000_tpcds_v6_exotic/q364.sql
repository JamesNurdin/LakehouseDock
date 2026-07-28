WITH filtered_customer AS (
    SELECT *
    FROM customer
    WHERE c_birth_day = 15
),
joined AS (
    SELECT
        c.c_customer_id,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        sr.sr_return_amt,
        ws.ws_net_profit,
        ws.ws_ext_list_price,
        wp.wp_link_count,
        wp.wp_type
    FROM filtered_customer c
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    WHERE ss.ss_ext_tax > 100.00
      AND ss.ss_ext_sales_price BETWEEN 500.00 AND 5000.00
      AND ws.ws_ext_list_price > 2000.00
      AND (wp.wp_type = 'content' OR wp.wp_type IS NULL)
)
SELECT
    c_customer_id,
    COUNT(DISTINCT ss_ticket_number) AS store_txn_cnt,
    SUM(ss_ext_sales_price) AS total_store_sales,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(ws_net_profit) AS total_web_profit,
    AVG(COALESCE(wp_link_count, 0)) AS avg_page_links
FROM joined
GROUP BY c_customer_id
ORDER BY total_store_sales DESC
LIMIT 100
