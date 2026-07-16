WITH combined_sales AS (
    SELECT cs.cs_promo_sk AS promo_sk,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_net_profit AS net_profit,
           cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    WHERE cs.cs_promo_sk IS NOT NULL
    UNION ALL
    SELECT ss.ss_promo_sk,
           ss.ss_sold_date_sk,
           ss.ss_net_profit,
           ss.ss_item_sk
    FROM store_sales ss
    WHERE ss.ss_promo_sk IS NOT NULL
    UNION ALL
    SELECT ws.ws_promo_sk,
           ws.ws_sold_date_sk,
           ws.ws_net_profit,
           ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_promo_sk IS NOT NULL
)
SELECT p.p_promo_id,
       i.i_brand,
       d.d_year,
       SUM(s.net_profit) AS total_net_profit,
       RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(s.net_profit) DESC) AS profit_rank
FROM combined_sales s
JOIN promotion p ON s.promo_sk = p.p_promo_sk
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY p.p_promo_id, i.i_brand, d.d_year
ORDER BY d.d_year, total_net_profit DESC
LIMIT 100
