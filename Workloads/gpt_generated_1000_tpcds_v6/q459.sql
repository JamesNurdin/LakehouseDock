/* goal: compute net contribution per item and promotion by combining store and catalog sales, returns, and reasons, categorizing profit levels */
WITH
  store_sales_agg AS (
    SELECT
      ss.ss_item_sk,
      ss.ss_promo_sk,
      SUM(ss.ss_net_profit)            AS total_store_net_profit,
      SUM(ss.ss_quantity)              AS total_store_quantity
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450905 AND 2451055
      AND ss.ss_sales_price > 0
      AND ss.ss_net_paid_inc_tax IS NOT NULL
      AND ss.ss_quantity >= 1
      AND ss.ss_store_sk IN (1, 2, 3)
    GROUP BY ss.ss_item_sk, ss.ss_promo_sk
  ),
  store_returns_agg AS (
    SELECT
      sr.sr_item_sk,
      r.r_reason_desc,
      SUM(sr.sr_net_loss) AS total_store_return_loss,
      COUNT(*)            AS return_cnt
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450905 AND 2451055
      AND sr.sr_fee > 20
      AND r.r_reason_desc LIKE '%warranty%'
      AND sr.sr_return_quantity > 0
      AND sr.sr_item_sk IS NOT NULL
    GROUP BY sr.sr_item_sk, r.r_reason_desc
  ),
  catalog_sales_agg AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_promo_sk,
      cp.cp_type,
      SUM(cs.cs_net_profit)   AS total_catalog_net_profit,
      SUM(cs.cs_quantity)     AS total_catalog_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450905 AND 2451055
      AND cp.cp_type = 'monthly'
      AND cs.cs_quantity > 0
      AND cs.cs_promo_sk IS NOT NULL
      AND cs.cs_net_profit IS NOT NULL
    GROUP BY cs.cs_item_sk, cs.cs_promo_sk, cp.cp_type
  ),
  catalog_returns_agg AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      r.r_reason_desc
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 0
      AND cr.cr_returned_date_sk BETWEEN 2450905 AND 2451055
      AND r.r_reason_desc LIKE '%model%'
      AND cr.cr_item_sk IS NOT NULL
  )
SELECT
  final.i_item_id,
  final.i_product_name,
  final.p_promo_name,
  final.cp_type,
  final.total_store_net_profit,
  final.total_catalog_net_profit,
  final.total_store_return_loss,
  final.total_catalog_return_amount,
  final.net_contribution,
  final.profit_band
FROM (
  SELECT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    csa.cp_type,
    ssa.total_store_net_profit,
    csa.total_catalog_net_profit,
    sra.total_store_return_loss,
    SUM(cra.cr_return_amount)                                 AS total_catalog_return_amount,
    (ssa.total_store_net_profit + csa.total_catalog_net_profit
       - COALESCE(sra.total_store_return_loss, 0)
       - COALESCE(SUM(cra.cr_return_amount), 0))               AS net_contribution,
    CASE
      WHEN (ssa.total_store_net_profit + csa.total_catalog_net_profit) > 10000 THEN 'High'
      WHEN (ssa.total_store_net_profit + csa.total_catalog_net_profit) BETWEEN 0 AND 10000 THEN 'Medium'
      ELSE 'Low'
    END                                                       AS profit_band
  FROM store_sales_agg ssa
  JOIN item i ON ssa.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ssa.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns_agg sra ON sra.sr_item_sk = i.i_item_sk
  JOIN catalog_sales_agg csa ON csa.cs_item_sk = i.i_item_sk AND csa.cs_promo_sk = p.p_promo_sk
  LEFT JOIN catalog_returns_agg cra ON cra.cr_item_sk = i.i_item_sk
  GROUP BY
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    csa.cp_type,
    ssa.total_store_net_profit,
    csa.total_catalog_net_profit,
    sra.total_store_return_loss
) final
WHERE final.net_contribution > 0
ORDER BY final.net_contribution DESC
LIMIT 100
