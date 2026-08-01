WITH
  -- Pages with high net profit in a given sold date range
  high_profit_pages AS (
    SELECT
      cp.cp_catalog_page_sk AS cp_sk,
      cp.cp_catalog_page_id,
      SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451000 AND 2451100
    GROUP BY cp.cp_catalog_page_sk, cp.cp_catalog_page_id
    HAVING SUM(cs.cs_net_profit) > 100000
  ),

  -- Pages that had promotions active for the same date window
  promo_active_pages AS (
    SELECT
      cp.cp_catalog_page_sk AS cp_sk,
      cp.cp_catalog_page_id,
      SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_start_date_sk <= 2451000
      AND p.p_end_date_sk   >= 2451100
    GROUP BY cp.cp_catalog_page_sk, cp.cp_catalog_page_id
    HAVING SUM(cs.cs_net_profit) > 50000
  ),

  -- Pages that satisfy both criteria (INTERSECT on the key set)
  intersected_pages AS (
    SELECT cp_sk FROM high_profit_pages
    INTERSECT
    SELECT cp_sk FROM promo_active_pages
  ),

  -- Union of the two page sets (DISTINCT union)
  union_pages AS (
    SELECT cp_sk, cp_catalog_page_id, total_net_profit FROM high_profit_pages
    UNION
    SELECT cp_sk, cp_catalog_page_id, total_net_profit FROM promo_active_pages
  )

SELECT
  up.cp_sk,
  up.cp_catalog_page_id,
  up.total_net_profit,
  (
    SELECT COUNT(DISTINCT cs2.cs_promo_sk)
    FROM catalog_sales cs2
    WHERE cs2.cs_catalog_page_sk = up.cp_sk
  ) AS distinct_promo_cnt
FROM union_pages up
WHERE up.cp_sk IN (SELECT cp_sk FROM intersected_pages)
  AND NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_catalog_page_sk = up.cp_sk
  )
ORDER BY up.total_net_profit DESC
LIMIT 100
