WITH cr_customers AS (
    SELECT cr_refunded_customer_sk AS cust_sk,
           SUM(cr_net_loss) AS total_loss,
           COUNT(*) AS cnt
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_refunded_customer_sk
),
sr_customers AS (
    SELECT sr_customer_sk AS cust_sk,
           SUM(sr_net_loss) AS total_loss,
           COUNT(*) AS cnt
    FROM store_returns
    WHERE sr_return_amt > 0
    GROUP BY sr_customer_sk
),
email_filtered AS (
    SELECT c.c_customer_sk AS cust_sk,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           c.c_email_address AS email,
           CASE
               WHEN regexp_like(c.c_email_address, '@example\\.com$') THEN 'Corporate'
               ELSE 'Personal'
           END AS email_type
    FROM customer c
    WHERE regexp_like(c.c_email_address, '^.+@.+\\..+$')
),
intersected AS (
    SELECT cust_sk FROM cr_customers
    INTERSECT
    SELECT cust_sk FROM sr_customers
),
excluded AS (
    SELECT ws.ws_bill_customer_sk AS cust_sk
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE '%promo%'
),
final_set AS (
    SELECT cust_sk FROM intersected
    EXCEPT
    SELECT cust_sk FROM excluded
)
SELECT ef.cust_sk,
       ef.full_name,
       ef.email,
       ef.email_type,
       cr.total_loss AS catalog_loss,
       sr.total_loss AS store_loss,
       CASE WHEN (COALESCE(cr.total_loss, 0) + COALESCE(sr.total_loss, 0)) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
       (
           SELECT COUNT(DISTINCT sr_inner.sr_store_sk)
           FROM store_returns sr_inner
           WHERE sr_inner.sr_customer_sk = ef.cust_sk
       ) AS stores_returned
FROM final_set fs
JOIN email_filtered ef ON fs.cust_sk = ef.cust_sk
LEFT JOIN cr_customers cr ON fs.cust_sk = cr.cust_sk
LEFT JOIN sr_customers sr ON fs.cust_sk = sr.cust_sk
ORDER BY loss_category DESC, catalog_loss DESC
LIMIT 100
