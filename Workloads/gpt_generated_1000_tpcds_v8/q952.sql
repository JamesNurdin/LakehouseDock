WITH
  -- full outer join between promotion and item (keeps unmatched rows from both sides)
  promo_item_full AS (
    SELECT
      p.p_promo_sk,
      p.p_promo_id,
      p.p_discount_active,
      i.i_item_sk,
      i.i_item_id,
      i.i_brand,
      i.i_category
    FROM promotion p
    FULL OUTER JOIN item i
      ON p.p_item_sk = i.i_item_sk
  ),

  -- sample a fraction of inventory and keep only rows with a decent stock level
  inventory_sample AS (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
    WHERE inv_quantity_on_hand > 600
  ),

  -- catalog return side of the union
  catalog_part AS (
    SELECT
      cr.cr_item_sk               AS item_sk,
      cp.cp_catalog_page_id      AS source_id,
      r.r_reason_desc            AS source_desc,
      cr.cr_return_amount        AS amount,
      CAST(NULL AS decimal(7,2)) AS net_paid,
      t.t_hour                    AS hour,
      c.c_customer_id            AS customer_id,
      w.w_warehouse_id           AS warehouse_id,
      pi.p_promo_id               AS promo_id,
      CAST(NULL AS varchar)      AS web_page_id,
      CAST(NULL AS varchar)      AS web_site_id
    FROM catalog_returns cr
    JOIN catalog_page cp   ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r          ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t       ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c       ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN warehouse w      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promo_item_full pi ON cr.cr_item_sk = pi.i_item_sk
    WHERE cr.cr_return_amount > 50
      AND t.t_hour BETWEEN 8 AND 20
      AND w.w_city = 'Seattle'
  ),

  -- web sales side of the union
  web_part AS (
    SELECT
      ws.ws_item_sk               AS item_sk,
      wp.wp_web_page_id           AS source_id,
      wsit.web_site_id            AS source_desc,
      CAST(NULL AS decimal(7,2))  AS amount,
      ws.ws_net_paid              AS net_paid,
      t.t_hour                    AS hour,
      c.c_customer_id            AS customer_id,
      w.w_warehouse_id           AS warehouse_id,
      pi.p_promo_id               AS promo_id,
      wp.wp_web_page_id           AS web_page_id,
      wsit.web_site_id            AS web_site_id
    FROM web_sales ws
    JOIN web_page wp   ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN time_dim t    ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c    ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w   ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promo_item_full pi ON ws.ws_item_sk = pi.i_item_sk
    WHERE ws.ws_net_paid > 100
      AND t.t_hour BETWEEN 8 AND 20
      AND wsit.web_state = 'CA'
  ),

  -- store sales side of the union
  store_part AS (
    SELECT
      ss.ss_item_sk               AS item_sk,
      CAST(NULL AS varchar)       AS source_id,
      CAST(NULL AS varchar)       AS source_desc,
      CAST(NULL AS decimal(7,2))  AS amount,
      ss.ss_net_paid              AS net_paid,
      t.t_hour                    AS hour,
      c.c_customer_id            AS customer_id,
      CAST(NULL AS varchar)       AS warehouse_id,
      p.p_promo_id                AS promo_id,
      CAST(NULL AS varchar)       AS web_page_id,
      CAST(NULL AS varchar)       AS web_site_id
    FROM store_sales ss
    JOIN time_dim t   ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i       ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p  ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c   ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_net_paid > 80
      AND t.t_hour BETWEEN 8 AND 20
  ),

  -- combine the three sources, removing duplicates
  union_data AS (
    SELECT * FROM catalog_part
    UNION DISTINCT
    SELECT * FROM web_part
    UNION DISTINCT
    SELECT * FROM store_part
  ),

  -- first level aggregation
  final_agg AS (
    SELECT
      ud.item_sk,
      MIN(ud.source_id)                           AS sample_source_id,
      SUM(ud.amount)                              AS total_return_amount,
      SUM(ud.net_paid)                            AS total_net_paid,
      COUNT(*)                                    AS activity_cnt,
      MAX(ud.hour)                                AS latest_hour,
      -- correlated scalar sub‑query: total inventory quantity for this item
      (SELECT SUM(inv_quantity_on_hand)
         FROM inventory inv
        WHERE inv.inv_item_sk = ud.item_sk)      AS total_inventory_qty
    FROM union_data ud
    GROUP BY ud.item_sk
  ),

  -- ranking and windowed totals, plus an EXISTS filter on promotion
  ranked AS (
    SELECT
      fa.*,
      SUM(fa.total_return_amount + fa.total_net_paid) OVER (ORDER BY (fa.total_return_amount + fa.total_net_paid) DESC) AS cumulative_rev,
      RANK() OVER (ORDER BY (fa.total_return_amount + fa.total_net_paid) DESC) AS rev_rank
    FROM final_agg fa
    WHERE fa.total_inventory_qty IS NOT NULL
      AND EXISTS (SELECT 1 FROM promotion p WHERE p.p_promo_id = fa.sample_source_id)
  )
SELECT
  rev_rank,
  item_sk,
  sample_source_id,
  total_return_amount,
  total_net_paid,
  activity_cnt,
  latest_hour,
  total_inventory_qty,
  cumulative_rev
FROM ranked
ORDER BY rev_rank
LIMIT 100
