WITH date_year AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
)
SELECT combined.d_year,
       combined.promo_category,
       combined.total_net_paid,
       combined.total_net_profit,
       combined.email_promo_count
FROM (
    SELECT dy.d_year,
           'EmailActive' AS promo_category,
           SUM(ss.ss_net_paid) AS total_net_paid,
           SUM(ss.ss_net_profit) AS total_net_profit,
           (SELECT COUNT(*) FROM promotion WHERE p_channel_email = 'Y') AS email_promo_count
    FROM store_sales ss
    JOIN date_year dy ON ss.ss_sold_date_sk = dy.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE p.p_channel_email = 'Y'
      AND ca.ca_state = 'CA'
    GROUP BY dy.d_year
    HAVING SUM(ss.ss_net_paid) > 10000

    UNION ALL

    SELECT dy.d_year,
           'EmailInactive' AS promo_category,
           SUM(ss.ss_net_paid) AS total_net_paid,
           SUM(ss.ss_net_profit) AS total_net_profit,
           (SELECT COUNT(*) FROM promotion WHERE p_channel_email = 'Y') AS email_promo_count
    FROM store_sales ss
    JOIN date_year dy ON ss.ss_sold_date_sk = dy.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE p.p_channel_email = 'N'
      AND ca.ca_state = 'TX'
    GROUP BY dy.d_year
    HAVING SUM(ss.ss_net_paid) > 10000
) AS combined
ORDER BY combined.d_year,
         combined.promo_category
