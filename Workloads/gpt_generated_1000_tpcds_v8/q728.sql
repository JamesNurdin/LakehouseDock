WITH
  sampled_items AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)   -- sample ~10% of items
  ),

  store_aggregates AS (
    SELECT
      d.d_year,
      s.s_store_sk,
      s.s_store_name,
      SUM(ss.ss_net_paid)            AS total_net_paid,
      COUNT(*)                       AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
    JOIN sampled_items i          ON ss.ss_item_sk = i.i_item_sk
    GROUP BY ROLLUP (d.d_year, s.s_store_sk, s.s_store_name)
  ),

  return_aggregates AS (
    SELECT
      d.d_year,
      w.w_warehouse_sk,
      w.w_warehouse_name,
      SUM(cr.cr_return_amount)       AS total_return_amount,
      COUNT(*)                       AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w               ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY ROLLUP (d.d_year, w.w_warehouse_sk, w.w_warehouse_name)
  ),

  promotion_agg AS (
    SELECT
      d.d_year,
      p.p_promo_sk,
      p.p_promo_name,
      SUM(p.p_cost)                  AS total_promo_cost
    FROM promotion p
    JOIN date_dim d               ON p.p_start_date_sk = d.d_date_sk
    GROUP BY ROLLUP (d.d_year, p.p_promo_sk, p.p_promo_name)
  ),

  combined AS (
    SELECT
      year,
      entity,
      total_amount,
      transaction_cnt,
      store_sk,
      warehouse_sk
    FROM (
      SELECT
        d_year           AS year,
        s_store_name     AS entity,
        total_net_paid   AS total_amount,
        sales_cnt        AS transaction_cnt,
        s_store_sk       AS store_sk,
        NULL             AS warehouse_sk
      FROM store_aggregates
      UNION
      SELECT
        d_year           AS year,
        w_warehouse_name AS entity,
        total_return_amount AS total_amount,
        return_cnt          AS transaction_cnt,
        NULL                AS store_sk,
        w_warehouse_sk      AS warehouse_sk
      FROM return_aggregates
    ) u
  ),

  final_join AS (
    SELECT
      COALESCE(c.year, p.d_year)                     AS year,
      c.entity,
      c.total_amount,
      c.transaction_cnt,
      p.p_promo_name,
      p.total_promo_cost,
      c.store_sk,
      c.warehouse_sk
    FROM combined c
    FULL OUTER JOIN promotion_agg p
      ON c.year = p.d_year
  )
SELECT
  fj.year,
  fj.entity,
  fj.total_amount,
  fj.transaction_cnt,
  fj.p_promo_name,
  fj.total_promo_cost,
  -- scalar subquery: total number of catalog pages for the "Books" department
  (SELECT COUNT(*) FROM catalog_page cp WHERE cp.cp_department = 'Books') AS total_book_pages,
  -- lateral subquery: average net paid per store (null when entity is not a store)
  l.avg_store_net_paid
FROM final_join fj
LEFT JOIN LATERAL (
  SELECT AVG(ss2.ss_net_paid) AS avg_store_net_paid
  FROM store_sales ss2
  WHERE ss2.ss_store_sk = fj.store_sk
) l ON TRUE
ORDER BY fj.year DESC, fj.total_amount DESC
LIMIT 100
