WITH
  catalog_agg AS (
    SELECT
      cp.cp_catalog_page_id AS id,
      cp.cp_description AS name,
      w.w_warehouse_name AS warehouse,
      concat(substr(cp.cp_description, 1, 30), '...') AS short_text,
      sum(cs.cs_net_paid) AS total_net_paid,
      sum(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(cp.cp_description, '(?i)econom')
      AND cp.cp_type LIKE 'C%'
      AND p.p_discount_active = 'Y'
    GROUP BY cp.cp_catalog_page_id,
             cp.cp_description,
             w.w_warehouse_name,
             concat(substr(cp.cp_description, 1, 30), '...')
  ),
  web_agg AS (
    SELECT
      p.p_promo_id AS id,
      p.p_promo_name AS name,
      w.w_warehouse_name AS warehouse,
      concat(substr(r.r_reason_desc, 1, 30), '...') AS short_text,
      sum(ws.ws_net_paid) AS total_net_paid,
      sum(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc IS NOT NULL
      AND regexp_like(r.r_reason_desc, '(?i)defect')
      AND p.p_promo_name LIKE '%Special%'
    GROUP BY p.p_promo_id,
             p.p_promo_name,
             w.w_warehouse_name,
             concat(substr(r.r_reason_desc, 1, 30), '...')
  )
SELECT
  id,
  name,
  warehouse,
  short_text,
  total_net_paid,
  total_quantity,
  row_number() OVER (ORDER BY total_net_paid DESC) AS overall_rank
FROM (
  SELECT id, name, warehouse, short_text, total_net_paid, total_quantity FROM catalog_agg
  UNION DISTINCT
  SELECT id, name, warehouse, short_text, total_net_paid, total_quantity FROM web_agg
) u
ORDER BY total_net_paid DESC
LIMIT 100
