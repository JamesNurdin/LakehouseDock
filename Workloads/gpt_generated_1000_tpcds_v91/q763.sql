WITH filtered_promos AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        regexp_extract(p.p_promo_id, 'AAAAAAA([A-Z])', 1) AS promo_suffix,
        substr(p.p_promo_id, 1, 5) AS promo_prefix
    FROM promotion p
    WHERE regexp_like(p.p_promo_id, '^AAAAAAA[A-Z]+$')
)

SELECT
    'store' AS source_type,
    fp.p_promo_id,
    concat(s.s_store_name, ' - ', fp.promo_suffix, ' (', fp.promo_prefix, ')') AS location_desc,
    sum(ss.ss_net_paid) AS total_net_paid,
    sum(ss.ss_quantity) AS total_qty,
    fp.promo_suffix
FROM store_sales ss
FULL OUTER JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN filtered_promos fp
    ON ss.ss_promo_sk = fp.p_promo_sk
LEFT JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
WHERE (d.d_year = 2002 OR d.d_year IS NULL)
  AND s.s_store_name LIKE '%Store%'
GROUP BY fp.p_promo_id, s.s_store_name, fp.promo_suffix, fp.promo_prefix

UNION

SELECT
    'web' AS source_type,
    fp.p_promo_id,
    concat(wsit.web_name, ' - ', fp.promo_suffix, ' (', fp.promo_prefix, ')') AS location_desc,
    sum(ws.ws_net_paid) AS total_net_paid,
    sum(ws.ws_quantity) AS total_qty,
    fp.promo_suffix
FROM web_sales ws
JOIN filtered_promos fp
    ON ws.ws_promo_sk = fp.p_promo_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN date_dim d2
    ON ws.ws_sold_date_sk = d2.d_date_sk
WHERE d2.d_year = 2002
  AND wsit.web_name LIKE '%Web%'
  AND regexp_like(wp.wp_url, '^https?://[^/]+/promo/[A-Z]+$')
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
    )
GROUP BY fp.p_promo_id, wsit.web_name, fp.promo_suffix, fp.promo_prefix

ORDER BY total_net_paid DESC
LIMIT 100
