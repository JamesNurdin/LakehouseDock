WITH
  sales_cte AS (
    SELECT
      cs.cs_warehouse_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_ext_sales_price,
      w.w_warehouse_name,
      cd.cd_gender
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_ext_tax > 100
      AND NOT EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = cs.cs_promo_sk
          AND p.p_discount_active = 'Y'
      )
  ),

  returns_cte AS (
    SELECT
      sr.sr_reason_sk,
      sr.sr_cdemo_sk,
      sr.sr_refunded_cash,
      r.r_reason_desc,
      cd.cd_gender
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_refunded_cash > 100
      AND NOT EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = -1 -- dummy condition, guarantees anti‑join
      )
  ),

  -- a small dimension derived from REASON (only a few rows)
  reason_dim AS (
    SELECT DISTINCT r_reason_desc
    FROM reason
    LIMIT 5
  ),

  -- a computed scalar set (single row) used in the cross join
  max_price_cte AS (
    SELECT MAX(cs_ext_sales_price) AS max_price
    FROM catalog_sales
  )

SELECT
  combined.source_type,
  combined.warehouse_name,
  combined.reason_desc,
  combined.gender,
  combined.metric,
  combined.total_related,
  ROW_NUMBER() OVER (PARTITION BY combined.source_type ORDER BY combined.metric DESC) AS rank
FROM (
  SELECT
    'sales'   AS source_type,
    cs.w_warehouse_name      AS warehouse_name,
    CAST(NULL AS varchar)    AS reason_desc,
    cd.cd_gender             AS gender,
    cs.cs_ext_sales_price    AS metric,
    (
      SELECT SUM(cs2.cs_ext_sales_price)
      FROM catalog_sales cs2
      WHERE cs2.cs_bill_cdemo_sk = cd.cd_demo_sk
    ) AS total_related
  FROM sales_cte cs
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk

  UNION ALL

  SELECT
    'returns' AS source_type,
    CAST(NULL AS varchar)    AS warehouse_name,
    r.r_reason_desc          AS reason_desc,
    cd.cd_gender             AS gender,
    sr.sr_refunded_cash      AS metric,
    (
      SELECT SUM(sr2.sr_refunded_cash)
      FROM store_returns sr2
      WHERE sr2.sr_reason_sk = sr.sr_reason_sk
    ) AS total_related
  FROM returns_cte sr
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
) AS combined
CROSS JOIN reason_dim
CROSS JOIN max_price_cte
ORDER BY combined.source_type, rank
LIMIT 100
