WITH
  -- Web sales filtered with a regex on the order number and a positive net paid
  ws_filtered AS (
    SELECT
      ws.ws_order_number,
      ws.ws_net_paid,
      ws.ws_sold_date_sk,
      ws.ws_web_site_sk
    FROM web_sales ws
    WHERE regexp_like(cast(ws.ws_order_number AS varchar), '^[0-9]{6}$')
      AND ws.ws_net_paid > 0
  ),

  -- Catalog returns filtered with the same regex on the order number
  cr_filtered AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
      AND regexp_like(cast(cr.cr_order_number AS varchar), '^[0-9]{6}$')
  ),

  -- Intersection of the two order‑number sets
  intersect_orders AS (
    SELECT ws_order_number FROM ws_filtered
    INTERSECT
    SELECT cr_order_number FROM cr_filtered
  ),

  -- Keys that exist in CALL_CENTER but not in CATALOG_PAGE
  except_cc_cp AS (
    SELECT cc.cc_call_center_sk AS key_id
    FROM call_center cc
    WHERE cc.cc_name LIKE '%Center%'
    EXCEPT
    SELECT cp.cp_catalog_page_sk AS key_id
    FROM catalog_page cp
    WHERE cp.cp_description LIKE '%page%'
  ),

  -- Full outer join of STORE_SALES and STORE on the supported FK
  full_join_sales_store AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_net_paid,
      s.s_store_name,
      s.s_city
    FROM store_sales ss
    FULL OUTER JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
  ),

  -- Anti‑semi join: web sales whose order number never appears in catalog returns
  anti_orders AS (
    SELECT ws.ws_order_number, ws.ws_net_paid
    FROM web_sales ws
    WHERE ws.ws_order_number NOT IN (
            SELECT cr.cr_order_number FROM catalog_returns cr
          )
  ),

  -- Extract a prefix from WEB_SITE name using regexp_extract and filter with LIKE
  site_prefixes AS (
    SELECT
      ws.ws_order_number,
      regexp_extract(w.web_name, '([A-Za-z]+)') AS site_prefix
    FROM web_sales ws
    JOIN web_site w
      ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_name LIKE '%Online%'
  )

SELECT
  d.d_date,
  COUNT(DISTINCT fjs.ss_sold_date_sk)                           AS sales_day_cnt,
  (SELECT COUNT(*) FROM intersect_orders)                      AS intersect_order_cnt,
  (SELECT COUNT(*) FROM except_cc_cp)                           AS except_key_cnt,
  SUM(fjs.ss_net_paid)                                          AS total_store_sales,
  (SELECT SUM(ao.ws_net_paid) FROM anti_orders ao)            AS total_anti_sales,
  (SELECT ARRAY_AGG(DISTINCT sp.site_prefix)
     FROM site_prefixes sp
     WHERE sp.site_prefix IS NOT NULL)                         AS site_prefixes
FROM full_join_sales_store fjs
JOIN date_dim d
  ON fjs.ss_sold_date_sk = d.d_date_sk
GROUP BY d.d_date
ORDER BY d.d_date DESC
LIMIT 100
