WITH
  sales_demo AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_quantity,
      cs.cs_promo_sk,
      hd.hd_demo_sk,
      hd.hd_buy_potential,
      hd.hd_vehicle_count,
      p.p_promo_name,
      p.p_discount_active,
      -- extract a numeric discount percent from the promo name, e.g. "10% Discount"
      regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS promo_discount_pct,
      CASE
        WHEN hd.hd_buy_potential LIKE '%5000%' THEN 'Mid'
        WHEN hd.hd_buy_potential LIKE '%10000%' THEN 'High'
        ELSE 'Low'
      END AS buy_potential_category
    FROM catalog_sales cs
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
      AND hd.hd_vehicle_count >= 0
  ),
  aggregated AS (
    SELECT
      s.hd_demo_sk,
      s.buy_potential_category,
      SUM(s.cs_net_paid) AS total_net_paid,
      COUNT(DISTINCT s.cs_order_number) AS orders_cnt,
      MAX(CAST(s.promo_discount_pct AS integer)) AS max_discount_pct,
      SUM(s.cs_quantity) AS total_quantity
    FROM sales_demo s
    WHERE NOT EXISTS (
      SELECT 1
      FROM store_returns sr
      JOIN household_demographics hd2
        ON sr.sr_hdemo_sk = hd2.hd_demo_sk
      JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
      WHERE hd2.hd_demo_sk = s.hd_demo_sk
        AND regexp_like(r.r_reason_desc, '(?i)damage')
    )
    GROUP BY s.hd_demo_sk, s.buy_potential_category
    HAVING SUM(s.cs_net_paid) > 1000
  )
SELECT
  a.hd_demo_sk,
  a.buy_potential_category,
  a.total_net_paid,
  a.orders_cnt,
  a.max_discount_pct,
  CASE WHEN a.total_quantity > 100 THEN 'Bulk' ELSE 'Regular' END AS purchase_type,
  SUM(a.total_net_paid) OVER (PARTITION BY a.hd_demo_sk) AS demo_total_net_paid,
  ROW_NUMBER() OVER (PARTITION BY a.hd_demo_sk ORDER BY a.total_net_paid DESC) AS rn
FROM aggregated a
ORDER BY demo_total_net_paid DESC, max_discount_pct DESC
LIMIT 100
