WITH
  -- 1. Aggregate inventory per item
  inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk
  ),

  -- 2. Union of catalog and web sales, each joined to promotion
  sales_union AS (
    SELECT cs.cs_item_sk AS item_sk,
           SUM(cs.cs_net_paid) AS net_paid,
           SUM(cs.cs_quantity) AS quantity_sold,
           p.p_promo_name AS promo_name,
           'catalog' AS sales_source
    FROM catalog_sales cs
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY cs.cs_item_sk, p.p_promo_name

    UNION DISTINCT

    SELECT ws.ws_item_sk AS item_sk,
           SUM(ws.ws_net_paid) AS net_paid,
           SUM(ws.ws_quantity) AS quantity_sold,
           p.p_promo_name AS promo_name,
           'web' AS sales_source
    FROM web_sales ws
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ws.ws_item_sk, p.p_promo_name
  ),

  -- 3. Intersection of item/reason pairs that appear both in catalog and store returns
  returns_intersect AS (
    SELECT cr.cr_item_sk AS item_sk,
           cr.cr_reason_sk AS reason_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
    INTERSECT
    SELECT sr.sr_item_sk AS item_sk,
           sr.sr_reason_sk AS reason_sk
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
  ),

  -- 4. Reason left‑joined to catalog_returns (to expose ship_mode) – used for the full outer join
  reason_cr AS (
    SELECT r.r_reason_sk,
           r.r_reason_desc,
           cr.cr_ship_mode_sk
    FROM reason r
    LEFT JOIN catalog_returns cr
      ON r.r_reason_sk = cr.cr_reason_sk
  ),

  -- 5. Full outer join between reasons (through catalog_returns) and ship modes
  reason_ship_full AS (
    SELECT rc.r_reason_sk,
           rc.r_reason_desc,
           sm.sm_ship_mode_sk,
           sm.sm_type
    FROM reason_cr rc
    FULL OUTER JOIN ship_mode sm
      ON rc.cr_ship_mode_sk = sm.sm_ship_mode_sk
  )

SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_category,
  inv.total_qty_on_hand,
  su.net_paid,
  su.quantity_sold,
  su.promo_name,
  cr.cr_return_quantity,
  sr.sr_return_quantity,
  ws.ws_net_paid AS web_net_paid,
  rsf.r_reason_desc,
  rsf.sm_type,
  ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY su.net_paid DESC) AS rn_category
FROM item i
LEFT JOIN inv_agg inv
  ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN sales_union su
  ON i.i_item_sk = su.item_sk
LEFT JOIN catalog_returns cr
  ON i.i_item_sk = cr.cr_item_sk
LEFT JOIN store_returns sr
  ON i.i_item_sk = sr.sr_item_sk
LEFT JOIN web_sales ws
  ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN reason_ship_full rsf
  ON cr.cr_reason_sk = rsf.r_reason_sk
LEFT JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN customer_address ca
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
LEFT JOIN returns_intersect ri
  ON i.i_item_sk = ri.item_sk
WHERE i.i_brand_id = 3
  AND i.i_color = 'Red'
  AND inv.total_qty_on_hand > 100
  AND su.net_paid > 1000
ORDER BY i.i_category, rn_category
LIMIT 100
