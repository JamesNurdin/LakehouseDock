WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM tpcds.customer c
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@[^@]+\\.org$')
      AND c.c_first_name LIKE 'A%'
)
SELECT
    fc.email_domain,
    COUNT(DISTINCT fc.c_customer_sk) AS customer_cnt,
    SUM(sr.sr_net_loss) AS total_store_loss,
    SUM(wr.wr_net_loss) AS total_web_loss,
    SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss
FROM filtered_customers fc
JOIN tpcds.store_returns sr
    ON sr.sr_customer_sk = fc.c_customer_sk
JOIN tpcds.web_returns wr
    ON wr.wr_refunded_customer_sk = fc.c_customer_sk
JOIN tpcds.web_sales ws
    ON ws.ws_order_number = wr.wr_order_number
WHERE ws.ws_ext_discount_amt > 0
GROUP BY fc.email_domain
HAVING SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
