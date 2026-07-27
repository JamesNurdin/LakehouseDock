WITH catalog_agg AS (
    SELECT p.p_promo_name AS promo_name,
           SUM(cs.cs_net_paid) AS total_sales,
           'Catalog' AS sales_source
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE p.p_channel_event = 'N'
      AND d.d_year = 2001
    GROUP BY p.p_promo_name
),
web_agg AS (
    SELECT p.p_promo_name AS promo_name,
           SUM(ws.ws_net_paid) AS total_sales,
           'Web' AS sales_source
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE p.p_channel_event = 'N'
      AND d.d_year = 2001
    GROUP BY p.p_promo_name
)
SELECT promo_name,
       total_sales,
       sales_source
FROM catalog_agg
UNION ALL
SELECT promo_name,
       total_sales,
       sales_source
FROM web_agg
ORDER BY total_sales DESC
LIMIT 100
