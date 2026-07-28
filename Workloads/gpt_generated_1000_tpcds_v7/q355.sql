WITH returns_with_sales AS (
    SELECT
        ws.ws_ext_sales_price,
        wr.wr_net_loss,
        c.c_email_address,
        c.c_customer_id
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^.+@[^@]+\\.com$')
      AND c.c_customer_id LIKE 'AAAAAAA%BA%'
)
SELECT
    regexp_extract(c_email_address, '@([^@]+)$', 1) AS email_domain,
    substring(c_customer_id, 9, 2) AS id_suffix,
    COUNT(*) AS return_count,
    SUM(wr_net_loss) AS total_net_loss,
    AVG(ws_ext_sales_price) AS avg_sales_price
FROM returns_with_sales
GROUP BY
    regexp_extract(c_email_address, '@([^@]+)$', 1),
    substring(c_customer_id, 9, 2)
ORDER BY total_net_loss DESC
LIMIT 20
