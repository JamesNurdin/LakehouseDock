WITH
  sales_agg AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      SUM(ss.ss_net_paid)      AS total_net_paid,
      SUM(ss.ss_quantity)      AS total_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_sold_time_sk
  ),
  returns_agg AS (
    SELECT
      cr.cr_catalog_page_sk,
      cr.cr_returned_date_sk,
      SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_catalog_page_sk, cr.cr_returned_date_sk
  )
SELECT *
FROM (
  -- Store‑sales branch
  SELECT
    'store_sales'               AS source,
    s.s_store_id                AS store_id,
    d_sales.d_date               AS sale_date,
    sa.total_net_paid           AS amount,
    sa.total_quantity           AS quantity,
    RANK() OVER (PARTITION BY s.s_store_id ORDER BY sa.total_net_paid DESC) AS rank,
    CASE WHEN sa.total_net_paid > 10000 THEN 'High' ELSE 'Low' END AS category
  FROM sales_agg sa
  JOIN store s               ON sa.ss_store_sk   = s.s_store_sk
  JOIN date_dim d_sales      ON sa.ss_sold_date_sk = d_sales.d_date_sk
  JOIN time_dim t_sales      ON sa.ss_sold_time_sk = t_sales.t_time_sk
  WHERE s.s_state               = 'CA'
    AND d_sales.d_year          = 2000
    AND s.s_number_employees   > 50
    AND s.s_market_id          = 1
    AND s.s_gmt_offset BETWEEN -8 AND -5
    AND s.s_tax_percentage    < 10

  UNION ALL

  -- Catalog‑returns (with web‑returns) branch
  SELECT
    'catalog_returns'          AS source,
    s2.s_store_id               AS store_id,
    d_ret.d_date                AS sale_date,
    cr_agg.total_return_amount AS amount,
    CAST(NULL AS integer)      AS quantity,
    RANK() OVER (PARTITION BY s2.s_store_id ORDER BY cr_agg.total_return_amount DESC) AS rank,
    CASE WHEN cr_agg.total_return_amount > 5000 THEN 'High' ELSE 'Low' END AS category
  FROM returns_agg cr_agg
  JOIN catalog_returns cr          ON cr.cr_catalog_page_sk = cr_agg.cr_catalog_page_sk
                                    AND cr.cr_returned_date_sk = cr_agg.cr_returned_date_sk
  JOIN catalog_page cp              ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN date_dim d_ret               ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN time_dim t_ret               ON cr.cr_returned_time_sk = t_ret.t_time_sk
  JOIN reason cr_reason             ON cr.cr_reason_sk = cr_reason.r_reason_sk
  JOIN ship_mode sm                 ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w                  ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN income_band ib_ref           ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
  JOIN store s2                     ON s2.s_closed_date_sk = d_ret.d_date_sk
  LEFT JOIN web_returns wr        ON wr.wr_returned_date_sk = d_ret.d_date_sk
  LEFT JOIN web_page wp            ON wr.wr_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN reason wr_reason       ON wr.wr_reason_sk = wr_reason.r_reason_sk
  LEFT JOIN date_dim d_wp_create   ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
  LEFT JOIN date_dim d_wp_access   ON wp.wp_access_date_sk   = d_wp_access.d_date_sk
  WHERE d_ret.d_year                 = 2000
    AND cp.cp_department             = 'Electronics'
    AND sm.sm_type                  = 'AIR'
    AND w.w_city                    = 'Los Angeles'
    AND cd_ref.cd_gender            = 'M'
    AND ib_ref.ib_lower_bound       > 50000
    AND EXISTS (SELECT 1 FROM ship_mode sm2 WHERE sm2.sm_carrier = 'UPS' AND sm2.sm_ship_mode_sk = sm.sm_ship_mode_sk)
) AS combined
ORDER BY source, rank
LIMIT 100
