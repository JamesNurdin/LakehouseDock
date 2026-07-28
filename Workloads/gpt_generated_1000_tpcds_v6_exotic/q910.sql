SELECT
  s.s_store_name,
  d.d_year,
  SUM(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
WHERE regexp_like(c.c_email_address, '@example\\.com$')
  AND s.s_city LIKE '%York%'
  AND d.d_year BETWEEN 2001 AND 2002
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE sr.sr_store_sk = s.s_store_sk
          AND regexp_like(r.r_reason_desc, '^Did not like')
      )
GROUP BY s.s_store_name, d.d_year
ORDER BY total_profit DESC
LIMIT 10
