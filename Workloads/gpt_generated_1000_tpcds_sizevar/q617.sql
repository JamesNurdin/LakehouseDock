WITH
  -- Sample a fraction of the item table
  item_sample AS (
    SELECT i_item_sk, i_brand, i_current_price
    FROM item
    TABLESAMPLE BERNOULLI (10)
    -- 10% of rows are sampled
  ),

  -- Aggregate store sales with many dimension joins, using a RIGHT OUTER JOIN to keep all dates
  store_sales_agg AS (
    SELECT
      s.s_store_name            AS dim1,
      d1.d_year                 AS dim2,
      i.i_brand                 AS dim3,
      SUM(ss.ss_ext_sales_price) AS amount,
      'store_sales'             AS metric
    FROM store_sales ss
    RIGHT JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk          -- 1
    JOIN store s ON ss.ss_store_sk = s.s_store_sk                         -- 2
    JOIN item_sample i ON ss.ss_item_sk = i.i_item_sk                     -- 3
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk    -- 4
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk        -- 5
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk                 -- 6
    WHERE EXISTS (
      SELECT 1
      FROM store_returns sr
      WHERE sr.sr_ticket_number = ss.ss_ticket_number
    )
    GROUP BY s.s_store_name, d1.d_year, i.i_brand
  ),

  -- Aggregate catalog returns with many dimension joins, using an inner join chain
  catalog_returns_agg AS (
    SELECT
      cc.cc_name                AS dim1,
      d2.d_year                 AS dim2,
      cp.cp_department          AS dim3,
      SUM(cr.cr_return_amount) AS amount,
      'catalog_returns'         AS metric
    FROM catalog_returns cr
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk          -- 7
    JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk          -- 8
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk -- 9
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk --10
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk       --11
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk                    --12
    JOIN item_sample i2 ON cr.cr_item_sk = i2.i_item_sk                 --13
    GROUP BY cc.cc_name, d2.d_year, cp.cp_department
  ),

  -- Union the two aggregates (deduplication ensured by UNION DISTINCT)
  combined AS (
    SELECT * FROM store_sales_agg
    UNION DISTINCT
    SELECT * FROM catalog_returns_agg
  ),

  -- A FULL OUTER JOIN between store and date_dim on the store‑closed date, only to satisfy the join‑type requirement
  store_date_full AS (
    SELECT s.s_store_name AS f_dim1,
           d3.d_year      AS f_dim2
    FROM store s
    FULL OUTER JOIN date_dim d3 ON s.s_closed_date_sk = d3.d_date_sk   -- 14
  ),

  -- Bring the FULL OUTER JOIN into the pipeline; the join is on the same keys used in the UNIONed result
  enriched AS (
    SELECT
      COALESCE(c.dim1, fd.f_dim1) AS final_dim1,
      COALESCE(c.dim2, fd.f_dim2) AS final_dim2,
      c.dim3,
      c.amount,
      c.metric
    FROM combined c
    FULL OUTER JOIN store_date_full fd
      ON c.dim1 = fd.f_dim1 AND c.dim2 = fd.f_dim2                     -- 15
  )

SELECT
  final_dim1,
  final_dim2,
  dim3,
  metric,
  SUM(amount) AS total_amount
FROM enriched
WHERE amount > 0
GROUP BY final_dim1, final_dim2, dim3, metric
ORDER BY total_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
