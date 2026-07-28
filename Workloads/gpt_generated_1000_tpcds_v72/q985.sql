WITH store_part AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        CASE WHEN SUM(ss.ss_quantity) > 1000 THEN 'High Volume' ELSE 'Low Volume' END AS volume_tag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS active_promos
        FROM promotion p2
        WHERE p2.p_item_sk = ss.ss_item_sk
          AND p2.p_start_date_sk <= ss.ss_sold_date_sk
          AND p2.p_end_date_sk >= ss.ss_sold_date_sk
    ) lp
    WHERE s.s_company_id = 1
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, i.i_category
),
web_part AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(ws.ws_net_paid) AS total_net_paid,
        CASE WHEN SUM(ws.ws_quantity) > 800 THEN 'High Volume' ELSE 'Low Volume' END AS volume_tag
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS active_promos
        FROM promotion p2
        WHERE p2.p_item_sk = ws.ws_item_sk
          AND p2.p_start_date_sk <= ws.ws_sold_date_sk
          AND p2.p_end_date_sk >= ws.ws_sold_date_sk
    ) lp
    WHERE wsite.web_company_id = 1
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, i.i_category
)
SELECT
    year,
    category,
    total_net_paid,
    volume_tag,
    'store' AS channel
FROM store_part
UNION ALL
SELECT
    year,
    category,
    total_net_paid,
    volume_tag,
    'web' AS channel
FROM web_part
ORDER BY year DESC, total_net_paid DESC
LIMIT 100
