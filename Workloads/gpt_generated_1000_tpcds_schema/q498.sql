WITH base_union AS (
  SELECT
    s.s_store_sk AS location_key,
    'store' AS location_type,
    s.s_store_name AS location_name,
    CASE
      WHEN regexp_like(p.p_promo_name, '^.*SALE.*$') THEN 'Sale'
      ELSE 'Other'
    END AS promo_category,
    sr.sr_net_loss AS net_loss,
    CONCAT(s.s_city, ', ', s.s_state) AS city_state
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE s.s_city LIKE '%York%'
    AND regexp_like(p.p_promo_name, '^[A-Z]{3}[0-9]{2}$')

  UNION DISTINCT

  SELECT
    w.w_warehouse_sk AS location_key,
    'warehouse' AS location_type,
    w.w_warehouse_name AS location_name,
    CASE
      WHEN regexp_like(cp.cp_description, '.*clearance.*') THEN 'Clearance'
      ELSE 'Other'
    END AS promo_category,
    cr.cr_net_loss AS net_loss,
    CONCAT(w.w_city, ', ', w.w_state) AS city_state
  FROM catalog_returns cr
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE w.w_city LIKE 'San%'
    AND regexp_like(cp.cp_description, '\\d{3}-[A-Z]{2}')
)
SELECT
  location_name,
  promo_category,
  SUM(net_loss) AS total_net_loss,
  COUNT(*) AS txn_count,
  CASE WHEN SUM(net_loss) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_indicator
FROM base_union u
WHERE EXISTS (
  SELECT 1
  FROM catalog_returns cr2
  JOIN warehouse w2 ON cr2.cr_warehouse_sk = w2.w_warehouse_sk
  WHERE w2.w_state = regexp_extract(u.city_state, ',\\s*(.*)$', 1)
)
GROUP BY ROLLUP (location_name, promo_category)
ORDER BY location_name NULLS LAST, promo_category
LIMIT 100
