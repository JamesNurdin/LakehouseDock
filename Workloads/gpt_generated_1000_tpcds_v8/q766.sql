WITH
  -- Catalog sales enriched with related dimensions
  catalog_part AS (
    SELECT
      cs.cs_order_number,
      cs.cs_ext_sales_price,
      cs.cs_net_paid_inc_ship,
      cs.cs_ext_tax,
      cs.cs_warehouse_sk,
      cs.cs_ship_mode_sk,
      cs.cs_bill_addr_sk,
      cs.cs_ship_addr_sk,
      cs.cs_promo_sk,
      ca_bill.ca_state            AS bill_state,
      ca_ship.ca_state            AS ship_state,
      sm.sm_type                  AS ship_mode_type,
      wh.w_warehouse_name         AS warehouse_name,
      p.p_promo_name              AS promo_name
    FROM catalog_sales cs
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN ship_mode sm          ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh          ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN promotion p          ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_sales_price > 1000
      AND cs.cs_ext_tax BETWEEN 0 AND 200
      AND cs.cs_net_paid_inc_ship > 500
      AND cs.cs_quantity >= 1
      AND p.p_discount_active = 'Y'
  ),

  -- Store sales enriched with related dimensions
  store_part AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_ext_sales_price,
      ss.ss_net_paid,
      ss.ss_quantity,
      ss.ss_addr_sk,
      ss.ss_promo_sk,
      ca.ca_state          AS store_state,
      p.p_promo_name       AS promo_name
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p          ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_ext_sales_price > 500
      AND ss.ss_quantity BETWEEN 1 AND 10
      AND ss.ss_net_paid > 100
      AND p.p_channel_tv = 'N'
      AND p.p_channel_demo = 'N'
  ),

  -- Intersect of keys from the two sales domains
  intersect_keys AS (
    SELECT cs.cs_order_number AS key FROM catalog_sales cs WHERE cs.cs_ext_sales_price > 1500
    INTERSECT
    SELECT ss.ss_ticket_number AS key FROM store_sales ss WHERE ss.ss_ext_sales_price > 800
  ),

  -- Keys that appear in catalog_sales but not in store_sales
  except_keys AS (
    SELECT cs.cs_order_number AS key FROM catalog_sales cs
    EXCEPT
    SELECT ss.ss_ticket_number AS key FROM store_sales ss
  ),

  -- Full outer join between the two enriched parts on promotion key
  full_joined AS (
    SELECT
      cp.cs_order_number,
      sp.ss_ticket_number,
      cp.cs_ext_sales_price,
      sp.ss_ext_sales_price,
      cp.cs_warehouse_sk,
      cp.cs_ship_mode_sk,
      cp.bill_state,
      cp.ship_state,
      sp.store_state,
      cp.ship_mode_type,
      cp.warehouse_name,
      COALESCE(cp.promo_name, sp.promo_name) AS promo_name,
      cp.cs_promo_sk                     -- keep promo key for later aggregation
    FROM catalog_part cp
    FULL OUTER JOIN store_part sp
      ON cp.cs_promo_sk = sp.ss_promo_sk
  ),

  -- Aggregation per warehouse and promotion
  aggregated AS (
    SELECT
      COALESCE(fj.cs_warehouse_sk, 0)                AS warehouse_sk,
      COALESCE(fj.warehouse_name, 'UNKNOWN')        AS warehouse_name,
      fj.promo_name,
      SUM(COALESCE(fj.cs_ext_sales_price, 0) + COALESCE(fj.ss_ext_sales_price, 0)) AS total_sales,
      COUNT(*)                                     AS txn_count,
      AVG(COALESCE(fj.cs_ext_sales_price, 0) + COALESCE(fj.ss_ext_sales_price, 0)) AS avg_sales
    FROM full_joined fj
    GROUP BY 1, 2, 3
  )
SELECT
  a.warehouse_name,
  a.promo_name,
  a.total_sales,
  a.txn_count,
  a.avg_sales,
  -- Correlated scalar sub‑query: how many catalog rows belong to this warehouse?
  (SELECT COUNT(*) FROM catalog_sales cs2 WHERE cs2.cs_warehouse_sk = a.warehouse_sk) AS catalog_rows_for_warehouse,
  RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank
FROM aggregated a
WHERE a.total_sales > 2000
  AND a.txn_count >= 5
ORDER BY a.total_sales DESC
LIMIT 100
