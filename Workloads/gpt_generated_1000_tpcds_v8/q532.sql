WITH
  -- Union of the three sales channels
  sales_union AS (
    SELECT
      cs.cs_sold_date_sk   AS sold_date_sk,
      cs.cs_sold_time_sk   AS sold_time_sk,
      cs.cs_item_sk        AS item_sk,
      cs.cs_promo_sk       AS promo_sk,
      cs.cs_quantity       AS quantity,
      cs.cs_net_paid_inc_ship_tax AS net_paid,
      'catalog'            AS sales_channel
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    UNION DISTINCT
    SELECT
      ss.ss_sold_date_sk   AS sold_date_sk,
      ss.ss_sold_time_sk   AS sold_time_sk,
      ss.ss_item_sk        AS item_sk,
      ss.ss_promo_sk       AS promo_sk,
      ss.ss_quantity       AS quantity,
      ss.ss_net_paid_inc_tax AS net_paid,
      'store'              AS sales_channel
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
    UNION DISTINCT
    SELECT
      ws.ws_sold_date_sk   AS sold_date_sk,
      ws.ws_sold_time_sk   AS sold_time_sk,
      ws.ws_item_sk        AS item_sk,
      ws.ws_promo_sk       AS promo_sk,
      ws.ws_quantity       AS quantity,
      ws.ws_net_paid_inc_ship_tax AS net_paid,
      'web'                AS sales_channel
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
  ),

  -- Items that have an active promotion
  item_promo AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      p.p_promo_sk,
      p.p_promo_name,
      p.p_discount_active
    FROM item i
    JOIN promotion p
      ON i.i_item_sk = p.p_item_sk
    WHERE p.p_discount_active = 'Y'
  ),

  -- Full outer join of inventory and item (keeps unmatched rows from both sides)
  inv_item_full AS (
    SELECT
      COALESCE(inv.inv_item_sk, i.i_item_sk) AS item_sk,
      inv.inv_quantity_on_hand,
      i.i_product_name,
      i.i_brand,
      i.i_category
    FROM inventory inv
    FULL OUTER JOIN item i
      ON inv.inv_item_sk = i.i_item_sk
  ),

  -- Items that never appear in a promotion (EXCEPT)
  non_promoted_items AS (
    SELECT i.i_item_sk
    FROM item i
    EXCEPT
    SELECT p.p_item_sk
    FROM promotion p
  ),

  -- Cross‑join of the time dimension with a small set of shift labels
  time_shifts AS (
    SELECT
      t.t_time_sk,
      t.t_shift,
      v.shift_label
    FROM time_dim t
    CROSS JOIN (VALUES 'Morning', 'Afternoon', 'Evening') AS v(shift_label)
    WHERE t.t_shift = v.shift_label
  ),

  -- Ranked aggregation of sales, with window functions and grouping sets
  ranked_sales AS (
    SELECT
      s.sold_date_sk,
      td.t_hour,
      ip.p_promo_name,
      i.i_brand,
      SUM(s.quantity)                     AS total_quantity,
      SUM(s.net_paid)                     AS total_net_paid,
      ROW_NUMBER() OVER (PARTITION BY ip.p_promo_name ORDER BY SUM(s.net_paid) DESC) AS rn_promo,
      RANK() OVER (ORDER BY SUM(s.net_paid) DESC)                               AS overall_rank
    FROM sales_union s
    JOIN time_dim td
      ON s.sold_time_sk = td.t_time_sk               -- allowed join rule
    JOIN item i
      ON s.item_sk = i.i_item_sk                     -- allowed join rule
    LEFT JOIN item_promo ip
      ON i.i_item_sk = ip.i_item_sk                  -- promotion linked via item
    LEFT JOIN inv_item_full inv
      ON i.i_item_sk = inv.item_sk                   -- inventory info (may be null)
    WHERE s.sold_date_sk BETWEEN 2451545 AND 2451910          -- surrogate‑date filter
      AND td.t_hour BETWEEN 8 AND 20                         -- business‑hour filter
      AND (ip.p_discount_active = 'Y' OR ip.p_discount_active IS NULL)
      AND EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = i.i_item_sk
              AND cr.cr_return_quantity > 0
          )                                                   -- semi‑join filter
    GROUP BY GROUPING SETS (
      (s.sold_date_sk, td.t_hour, ip.p_promo_name, i.i_brand),
      (s.sold_date_sk, td.t_hour, i.i_brand),
      (s.sold_date_sk, td.t_hour)
    )
  )

SELECT DISTINCT
  rs.sold_date_sk,
  rs.t_hour,
  rs.p_promo_name,
  rs.i_brand,
  rs.total_quantity,
  rs.total_net_paid,
  rs.rn_promo,
  rs.overall_rank,
  CASE WHEN rs.rn_promo = 1 THEN 'TopPromoItem' ELSE 'Other' END AS promo_rank_category
FROM ranked_sales rs
WHERE rs.overall_rank <= 10                     -- keep only top‑10 overall rows
ORDER BY rs.total_net_paid DESC
LIMIT 100
