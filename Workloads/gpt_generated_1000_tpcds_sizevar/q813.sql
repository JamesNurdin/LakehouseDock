WITH
    promo_sales AS (
        SELECT
            cs.cs_bill_customer_sk AS customer_sk,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            COUNT(*) AS order_cnt,
            REGEXP_EXTRACT(p.p_promo_name, '(\\d+)', 1) AS promo_number
        FROM catalog_sales cs
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        WHERE REGEXP_LIKE(p.p_promo_name, '^.*[0-9].*$')
          AND p.p_channel_email = 'Y'
        GROUP BY cs.cs_bill_customer_sk, REGEXP_EXTRACT(p.p_promo_name, '(\\d+)', 1)
    ),
    high_profit_customers AS (
        SELECT
            ss.ss_customer_sk AS customer_sk,
            SUM(ss.ss_net_profit) AS total_profit,
            CASE
                WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High'
                WHEN SUM(ss.ss_net_profit) > 0 THEN 'Medium'
                ELSE 'Low'
            END AS profit_category
        FROM store_sales ss
        GROUP BY ss.ss_customer_sk
    ),
    web_email_customers AS (
        SELECT DISTINCT
            ws.ws_bill_customer_sk AS customer_sk,
            c.c_email_address
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        WHERE REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    ),
    returns_customers AS (
        SELECT DISTINCT sr.sr_customer_sk AS customer_sk
        FROM store_returns sr
    )
SELECT
    customer_sk,
    c_first_name,
    c_last_name,
    profit_category,
    total_profit,
    total_sales,
    promo_tag,
    avg_profit_all
FROM (
    SELECT
        hp.customer_sk,
        c.c_first_name,
        c.c_last_name,
        hp.profit_category,
        hp.total_profit,
        ps.total_sales,
        CASE WHEN ps.promo_number IS NOT NULL THEN CONCAT('Promo', ps.promo_number) ELSE 'NoPromo' END AS promo_tag,
        (SELECT AVG(total_profit) FROM high_profit_customers) AS avg_profit_all
    FROM high_profit_customers hp
    JOIN customer c ON hp.customer_sk = c.c_customer_sk
    JOIN promo_sales ps ON hp.customer_sk = ps.customer_sk
    WHERE hp.profit_category = 'High'
      AND hp.customer_sk IN (SELECT customer_sk FROM web_email_customers)
) base
EXCEPT
SELECT
    hp.customer_sk,
    c.c_first_name,
    c.c_last_name,
    hp.profit_category,
    hp.total_profit,
    ps.total_sales,
    CASE WHEN ps.promo_number IS NOT NULL THEN CONCAT('Promo', ps.promo_number) ELSE 'NoPromo' END AS promo_tag,
    (SELECT AVG(total_profit) FROM high_profit_customers) AS avg_profit_all
FROM returns_customers rc
JOIN high_profit_customers hp ON rc.customer_sk = hp.customer_sk
JOIN customer c ON hp.customer_sk = c.c_customer_sk
JOIN promo_sales ps ON hp.customer_sk = ps.customer_sk
INTERSECT
SELECT
    hp.customer_sk,
    c.c_first_name,
    c.c_last_name,
    hp.profit_category,
    hp.total_profit,
    ps.total_sales,
    CASE WHEN ps.promo_number IS NOT NULL THEN CONCAT('Promo', ps.promo_number) ELSE 'NoPromo' END AS promo_tag,
    (SELECT AVG(total_profit) FROM high_profit_customers) AS avg_profit_all
FROM web_email_customers wc
JOIN high_profit_customers hp ON wc.customer_sk = hp.customer_sk
JOIN customer c ON hp.customer_sk = c.c_customer_sk
JOIN promo_sales ps ON hp.customer_sk = ps.customer_sk
WHERE wc.c_email_address LIKE '%@example.com'
ORDER BY total_profit DESC
LIMIT 100
