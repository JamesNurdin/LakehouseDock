/*
Goal: Identify the combined sales and return activity per item brand and category, broken out by year and transaction type, while demonstrating deep joins across all five TPC‑DS tables, re‑using dimension tables under multiple aliases, applying a TABLESAMPLE, a semi‑join, a FULL OUTER JOIN, a UNION, a CASE expression, GROUP BY CUBE, ordering and limiting the result.
*/
WITH
  /* Sample a fraction of the large fact table */
  sales_sample AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
  ),

  /* Join sales to all relevant dimensions (multiple aliases of date_dim and item) */
  sales_join AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_paid_inc_tax,
      cs.cs_quantity,
      cs.cs_sold_date_sk,
      cs.cs_ship_date_sk,
      cs.cs_item_sk,
      cs.cs_promo_sk,
      d_sold.d_year               AS sold_year,
      d_ship.d_year               AS ship_year,
      i_sales.i_brand,
      i_sales.i_category,
      p.p_promo_name,
      d_promo_start.d_date       AS promo_start_date,
      d_promo_end.d_date         AS promo_end_date,
      i_promo_item.i_brand        AS promo_item_brand
    FROM sales_sample cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk               -- 1
    JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk               -- 2
    JOIN item i_sales
      ON cs.cs_item_sk = i_sales.i_item_sk                   -- 3
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk                       -- 4
    JOIN date_dim d_promo_start
      ON p.p_start_date_sk = d_promo_start.d_date_sk        -- 5
    JOIN date_dim d_promo_end
      ON p.p_end_date_sk = d_promo_end.d_date_sk            -- 6
    JOIN item i_promo_item
      ON p.p_item_sk = i_promo_item.i_item_sk               -- 7
  ),

  /* Join returns to their own date and item dimensions */
  returns_join AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_returned_date_sk,
      cr.cr_item_sk,
      d_ret.d_year          AS return_year,
      i_ret.i_brand,
      i_ret.i_category
    FROM catalog_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk            -- 8
    JOIN item i_ret
      ON cr.cr_item_sk = i_ret.i_item_sk                      -- 9
  ),

  /* Semi‑join: keep only sales that have a matching return */
  sales_filtered AS (
    SELECT *
    FROM sales_join sj
    WHERE EXISTS (
      SELECT 1
      FROM returns_join rj
      WHERE rj.cr_order_number = sj.cs_order_number
    )
  ),

  /* UNION of the two transaction streams */
  unioned AS (
    SELECT
      cs_order_number AS order_number,
      cs_net_paid_inc_tax AS amount,
      cs_quantity       AS quantity,
      sold_year          AS year,
      i_brand,
      i_category,
      'sale'   AS txn_type
    FROM sales_filtered
    UNION DISTINCT
    SELECT
      cr_order_number AS order_number,
      cr_return_amount AS amount,
      cr_return_quantity AS quantity,
      return_year       AS year,
      i_brand,
      i_category,
      'return' AS txn_type
    FROM returns_join
  ),

  /* FULL OUTER JOIN to bring in month‑level information for every year present in either stream */
  full_joined AS (
    SELECT
      u.order_number,
      u.amount,
      u.quantity,
      u.year,
      u.i_brand,
      u.i_category,
      u.txn_type,
      d.d_month_seq
    FROM unioned u
    FULL OUTER JOIN date_dim d
      ON u.year = d.d_year                                   -- 10 (full outer join)
  )

SELECT
  year,
  i_brand,
  i_category,
  txn_type,
  COUNT(DISTINCT order_number)                     AS orders_cnt,
  SUM(amount)                                      AS total_amount,
  SUM(quantity)                                    AS total_quantity,
  CASE
    WHEN txn_type = 'sale'  THEN SUM(amount) * 0.90  -- example discount for sales
    ELSE SUM(amount) * 1.10                        -- surcharge for returns
  END                                              AS adjusted_amount,
  d_month_seq
FROM full_joined
GROUP BY CUBE (year, i_brand, i_category, txn_type, d_month_seq)
ORDER BY year DESC, i_brand, i_category
LIMIT 100
