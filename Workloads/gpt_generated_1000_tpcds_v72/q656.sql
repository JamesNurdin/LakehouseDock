WITH store_part AS (
    SELECT
        d.d_year AS year,
        s.s_store_id AS location_id,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
        CASE WHEN SUM(ss.ss_net_profit) > (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) THEN 'ABOVE_AVG' ELSE 'BELOW_AVG' END AS profit_vs_avg
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND EXISTS (
          SELECT 1 FROM promotion p
          WHERE p.p_promo_sk = ss.ss_promo_sk
            AND p.p_start_date_sk <= ss.ss_sold_date_sk
            AND p.p_end_date_sk >= ss.ss_sold_date_sk
      )
    GROUP BY d.d_year, s.s_store_id
    HAVING SUM(ss.ss_net_profit) > 1000
),
web_part AS (
    SELECT
        d.d_year AS year,
        w.web_site_id AS location_id,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold,
        CASE WHEN SUM(ws.ws_net_profit) > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) THEN 'ABOVE_AVG' ELSE 'BELOW_AVG' END AS profit_vs_avg
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ws.ws_promo_sk IS NOT NULL
    GROUP BY d.d_year, w.web_site_id
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT DISTINCT *
FROM (
    SELECT * FROM store_part
    UNION ALL
    SELECT * FROM web_part
) combined
LIMIT 100
