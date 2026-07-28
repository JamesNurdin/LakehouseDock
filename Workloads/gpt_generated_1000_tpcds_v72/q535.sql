-- Goal: Summarize net paid revenue by store, catalog page, and web site for the year 2022, 
-- including promotion details, and filter out store‑sales that have a matching return. 
-- The query joins all ten selected tables, re‑uses the PROMOTION and DATE_DIM tables under 
-- different aliases, contains scalar sub‑queries, an anti‑join, and combines three sub‑queries
-- with UNION ALL.
WITH
-- Store sales aggregation (uses STORE, STORE_SALES, PROMOTION, DATE_DIM and anti‑joins CATALOG_RETURNS)
store_agg AS (
    SELECT
        s.s_store_id                           AS entity_id,
        p_store.p_promo_id                     AS promo_id,
        SUM(ss.ss_net_paid)                   AS total_net_paid,
        COUNT(*)                               AS txn_count,
        d_ss.d_year                            AS sales_year,
        'store'                                AS source_type,
        (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_promo_id = p_store.p_promo_id) AS promo_count,
        CAST(NULL AS varchar)                 AS reason_desc
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p_store ON ss.ss_promo_sk = p_store.p_promo_sk
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    WHERE d_ss.d_year = 2022
      AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = ss.ss_item_sk
              AND cr.cr_returned_date_sk = d_ss.d_date_sk
        )
    GROUP BY s.s_store_id, p_store.p_promo_id, d_ss.d_year
),

-- Catalog sales aggregation (uses CATALOG_SALES, CATALOG_PAGE, PROMOTION, DATE_DIM,
-- joins to CATALOG_RETURNS and REASON for the optional reason description)
catalog_agg AS (
    SELECT
        cp.cp_catalog_page_id                 AS entity_id,
        p_cat.p_promo_id                       AS promo_id,
        SUM(cs.cs_net_paid)                   AS total_net_paid,
        COUNT(*)                               AS txn_count,
        d_cs.d_year                            AS sales_year,
        'catalog'                              AS source_type,
        (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_promo_id = p_cat.p_promo_id) AS promo_count,
        MIN(r.r_reason_desc)                  AS reason_desc
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p_cat ON cs.cs_promo_sk = p_cat.p_promo_sk
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    LEFT JOIN catalog_returns cr ON cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d_cs.d_year = 2022
    GROUP BY cp.cp_catalog_page_id, p_cat.p_promo_id, d_cs.d_year
),

-- Web sales aggregation (uses WEB_SALES, WEB_SITE, PROMOTION, DATE_DIM)
web_agg AS (
    SELECT
        w.web_site_id                         AS entity_id,
        p_web.p_promo_id                      AS promo_id,
        SUM(ws.ws_net_paid)                   AS total_net_paid,
        COUNT(*)                              AS txn_count,
        d_ws.d_year                           AS sales_year,
        'web'                                 AS source_type,
        (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_promo_id = p_web.p_promo_id) AS promo_count,
        CAST(NULL AS varchar)                AS reason_desc
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN promotion p_web ON ws.ws_promo_sk = p_web.p_promo_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year = 2022
    GROUP BY w.web_site_id, p_web.p_promo_id, d_ws.d_year
)

SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY total_net_paid DESC
LIMIT 100
