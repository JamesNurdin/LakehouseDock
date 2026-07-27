WITH store_avg_profit AS (
    SELECT s.s_store_sk,
           AVG(ss.ss_net_profit) AS avg_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk
)
SELECT
    s.s_store_name,
    s.s_city,
    d.d_year,
    COUNT(*) AS sales_transactions,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales,
    regexp_extract(s.s_store_name, '(\\w+)', 1) AS store_name_first_word,
    SUM(CASE WHEN regexp_like(c.c_email_address, '^.+@gmail\\.com$') THEN 1 ELSE 0 END) AS gmail_customer_count
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN store_avg_profit sap ON s.s_store_sk = sap.s_store_sk
WHERE sap.avg_profit > (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2)
  AND s.s_city LIKE 'A%'
  AND regexp_like(s.s_store_name, '^.*Store.*$')
GROUP BY s.s_store_name,
         s.s_city,
         d.d_year,
         regexp_extract(s.s_store_name, '(\\w+)', 1)
ORDER BY total_net_paid DESC
LIMIT 100
