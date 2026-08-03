WITH
  -- Build an array from two numeric columns of catalog_returns
  cr_array AS (
    SELECT
      cr.*,
      array[cr.cr_return_amount, cr.cr_fee] AS amount_array
    FROM catalog_returns cr
  ),

  -- Sample a fraction of store_sales
  sales_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
  ),

  -- Aggregate the joined data
  base AS (
    SELECT
      d_date.d_year,
      d_date.d_date,
      w.w_warehouse_name,
      sm.sm_type,
      p.p_promo_name,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(cr_array.cr_net_loss) AS total_return_loss,
      SUM(val) AS total_amount_array_sum,
      CASE
        WHEN SUM(ss.ss_ext_sales_price) > 0 THEN SUM(cr_array.cr_net_loss) / SUM(ss.ss_ext_sales_price)
        ELSE NULL
      END AS loss_ratio
    FROM cr_array
    -- Unnest the array built from catalog_returns
    CROSS JOIN UNNEST(cr_array.amount_array) AS t(val)
    -- Join to the common date dimension (used by many tables)
    JOIN date_dim d_date
      ON cr_array.cr_returned_date_sk = d_date.d_date_sk
    -- Store sales sampled rows share the same date key
    JOIN sales_sample ss
      ON ss.ss_sold_date_sk = d_date.d_date_sk
    -- Promotion linked to the sale
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    -- Promotion start and end dates (different aliases of date_dim)
    JOIN date_dim d_promo_start
      ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
      ON p.p_end_date_sk = d_promo_end.d_date_sk
    -- Ship mode and warehouse from the return record
    JOIN ship_mode sm
      ON cr_array.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cr_array.cr_warehouse_sk = w.w_warehouse_sk
    -- Web site open and close dates (two aliases of the same table)
    JOIN web_site ws_open
      ON ws_open.web_open_date_sk = d_date.d_date_sk
    JOIN web_site ws_close
      ON ws_close.web_close_date_sk = d_date.d_date_sk
    -- Web page creation and access dates (two aliases)
    JOIN web_page wp_creation
      ON wp_creation.wp_creation_date_sk = d_date.d_date_sk
    JOIN web_page wp_access
      ON wp_access.wp_access_date_sk = d_date.d_date_sk
    -- Existence check for an active promotion
    WHERE EXISTS (
      SELECT 1
      FROM promotion p2
      WHERE p2.p_promo_sk = ss.ss_promo_sk
        AND p2.p_discount_active = 'Y'
    )
    GROUP BY
      d_date.d_year,
      d_date.d_date,
      w.w_warehouse_name,
      sm.sm_type,
      p.p_promo_name
  )
SELECT
  b.d_year,
  b.d_date,
  b.w_warehouse_name,
  b.sm_type,
  b.p_promo_name,
  b.total_sales,
  b.total_return_loss,
  b.total_amount_array_sum,
  b.loss_ratio,
  -- Running total of sales per warehouse over time
  SUM(b.total_sales) OVER (
    PARTITION BY b.w_warehouse_name
    ORDER BY b.d_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total_sales
FROM base b
ORDER BY b.total_sales DESC
LIMIT 100
