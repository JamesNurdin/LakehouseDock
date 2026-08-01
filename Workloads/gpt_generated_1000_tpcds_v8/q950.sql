WITH
  -- Restrict date dimension to a single year for simplicity (e.g., 2002)
  date_sales AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2002
  ),

  -- Store sales enriched with promotion array (used later with UNNEST)
  sales_base AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_promo_sk,
      ss.ss_ticket_number,
      ss.ss_net_profit,
      d1.d_year,
      i.i_category,
      s.s_store_name,
      p.p_promo_id,
      ARRAY[p.p_promo_id] AS promo_ids
    FROM store_sales ss
    JOIN date_sales d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  ),

  -- Store returns (introduces another join to reason and store)
  return_base AS (
    SELECT
      sr.sr_store_sk,
      sr.sr_net_loss,
      d2.d_year,
      r.r_reason_desc
    FROM store_returns sr
    JOIN date_sales d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
  ),

  -- Catalog returns (adds call_center, catalog_page, reason)
  catalog_ret_base AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_net_loss,
      d3.d_year,
      cc.cc_name,
      cp.cp_department,
      r2.r_reason_desc
    FROM catalog_returns cr
    JOIN date_sales d3 ON cr.cr_returned_date_sk = d3.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
  ),

  -- Web sales (adds promotion again under a different alias)
  web_sales_base AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_order_number,
      ws.ws_net_profit,
      d4.d_year,
      i2.i_category,
      p2.p_promo_id
    FROM web_sales ws
    JOIN date_sales d4 ON ws.ws_sold_date_sk = d4.d_date_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
  ),

  -- Web returns (adds reason)
  web_ret_base AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_net_loss,
      d5.d_year,
      r3.r_reason_desc
    FROM web_returns wr
    JOIN date_sales d5 ON wr.wr_returned_date_sk = d5.d_date_sk
    JOIN reason r3 ON wr.wr_reason_sk = r3.r_reason_sk
  ),

  -- Stores that appear in both sales and returns for the chosen year (INTERSECT)
  intersected_store_ids AS (
    SELECT ss.ss_store_sk AS s_store_sk
    FROM store_sales ss
    JOIN date_sales d ON ss.ss_sold_date_sk = d.d_date_sk
    INTERSECT
    SELECT sr.sr_store_sk
    FROM store_returns sr
    JOIN date_sales d ON sr.sr_returned_date_sk = d.d_date_sk
  ),

  -- Union of store‑side sales and store‑side returns (UNION DISTINCT)
  combined_sales AS (
    SELECT
      s.s_store_name      AS store_name,
      d1.d_year           AS year,
      i.i_category        AS category,
      ss.ss_net_profit    AS net_profit,
      0.0                 AS net_loss,
      s.s_store_sk        AS store_id
    FROM store_sales ss
    JOIN date_sales d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_store_sk IN (SELECT s_store_sk FROM intersected_store_ids)

    UNION DISTINCT

    SELECT
      s2.s_store_name,
      d2.d_year,
      i2.i_category,
      0.0,
      sr.sr_net_loss,
      s2.s_store_sk
    FROM store_returns sr
    JOIN date_sales d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
    JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
    WHERE s2.s_store_sk IN (SELECT s_store_sk FROM intersected_store_ids)
  )

SELECT
  cs.store_name,
  cs.year,
  cs.category,
  SUM(cs.net_profit)                AS total_net_profit,
  SUM(cs.net_loss)                  AS total_net_loss,
  COUNT(DISTINCT cs.store_id)       AS distinct_store_count,
  RANK() OVER (PARTITION BY cs.year ORDER BY SUM(cs.net_profit) DESC) AS profit_rank,
  promo_id
FROM combined_sales cs
JOIN sales_base sb
  ON cs.store_id = sb.ss_store_sk AND cs.year = sb.d_year
CROSS JOIN UNNEST(sb.promo_ids) AS t(promo_id)      -- LATERAL UNNEST of promotion id array
GROUP BY
  cs.store_name,
  cs.year,
  cs.category,
  cs.store_id,
  promo_id
ORDER BY
  cs.year DESC,
  total_net_profit DESC
LIMIT 100
