WITH sales_filtered AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_county,
        s.s_zip,
        c.c_customer_sk,
        c.c_email_address,
        ss.ss_net_paid,
        ss.ss_net_profit,
        regexp_extract(c.c_email_address, '([^@]+)@(.+)', 2) AS email_domain,
        CASE WHEN regexp_like(c.c_email_address, '\\.org$') THEN 'ORG' ELSE 'OTHER' END AS email_type,
        ss.ss_sold_date_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE s.s_zip LIKE '4%'
      AND regexp_like(c.c_email_address, '^[A-Za-z]+\\.[A-Za-z]+@')
      AND s.s_store_id IN (
          SELECT s2.s_store_id
          FROM store s2
          WHERE s2.s_city LIKE 'A%'
      )
)
SELECT
    sf.s_store_id,
    sf.s_store_name,
    sf.s_county,
    sf.email_domain,
    sf.email_type,
    COUNT(*) AS sales_cnt,
    SUM(sf.ss_net_paid) AS total_net_paid,
    SUM(sf.ss_net_profit) AS total_net_profit,
    (
        SELECT SUM(sr.sr_return_amt)
        FROM store_returns sr
        WHERE sr.sr_store_sk = sf.s_store_sk
    ) AS total_return_amt,
    CASE WHEN SUM(sf.ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
FROM sales_filtered sf
GROUP BY sf.s_store_id, sf.s_store_name, sf.s_county, sf.email_domain, sf.email_type, sf.s_store_sk
HAVING COUNT(*) > 5
ORDER BY total_net_profit DESC
LIMIT 100
