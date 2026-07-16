SELECT p.p_promo_id,
       coalesce(cs.total_net_paid, 0) + coalesce(ss.total_net_paid, 0) + coalesce(ws.total_net_paid, 0) AS total_net_paid
FROM promotion p
LEFT JOIN (
    SELECT cs.cs_promo_sk AS promo_sk, sum(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs.cs_promo_sk
) cs ON p.p_promo_sk = cs.promo_sk
LEFT JOIN (
    SELECT ss.ss_promo_sk AS promo_sk, sum(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_promo_sk
) ss ON p.p_promo_sk = ss.promo_sk
LEFT JOIN (
    SELECT ws.ws_promo_sk AS promo_sk, sum(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_promo_sk
) ws ON p.p_promo_sk = ws.promo_sk
ORDER BY total_net_paid DESC
LIMIT 10
