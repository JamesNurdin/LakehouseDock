WITH
  sales_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(ss.ss_net_profit)                     AS total_net_profit,
        SUM(ss.ss_ext_sales_price)                AS total_sales,
        COUNT(*)                                   AS sales_transactions
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p              ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv       ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN warehouse w         ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp         ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site ws         ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ss.ss_quantity > 1
      AND p.p_discount_active = 'Y'
      AND (w.w_state = 'CA' OR w.w_state IS NULL)
      AND (ws.web_country = 'United States' OR ws.web_country IS NULL)
    GROUP BY s.s_store_id, d.d_year
  ),

  catalog_agg AS (
    SELECT
        cs.cs_warehouse_sk,
        d.d_year,
        SUM(cs.cs_net_profit)          AS total_net_profit,
        SUM(cs.cs_ext_sales_price)     AS total_sales,
        COUNT(*)                       AS catalog_transactions
    FROM catalog_sales cs
    JOIN date_dim d          ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t          ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w         ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p         ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cs.cs_quantity >= 2
      AND sm.sm_type = 'AIR'
      AND p.p_promo_name LIKE '%Summer%'
      AND w.w_gmt_offset = -5.00
    GROUP BY cs.cs_warehouse_sk, d.d_year
  ),

  returns_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(sr.sr_net_loss)           AS total_net_loss,
        COUNT(*)                      AS return_cnt,
        r.r_reason_desc
    FROM store_returns sr
    JOIN date_dim d            ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t            ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s               ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r              ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND sr.sr_return_quantity > 0
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY s.s_store_id, d.d_year, r.r_reason_desc
  ),

  combined AS (
    SELECT
        CAST(s_store_id AS varchar) AS entity_id,
        d_year,
        total_net_profit,
        total_sales,
        sales_transactions,
        NULL          AS warehouse_sk,
        NULL          AS catalog_transactions
    FROM sales_agg
    UNION ALL
    SELECT
        CAST(cs_warehouse_sk AS varchar) AS entity_id,
        d_year,
        total_net_profit,
        total_sales,
        NULL,
        cs_warehouse_sk,
        catalog_transactions
    FROM catalog_agg
  )

SELECT
  c.entity_id,
  c.d_year,
  SUM(c.total_net_profit)                         AS sum_net_profit,
  SUM(c.total_sales)                              AS sum_total_sales,
  SUM(COALESCE(c.sales_transactions, 0))          AS total_sales_tx,
  SUM(COALESCE(c.catalog_transactions, 0))        AS total_catalog_tx,
  MAX(r.r_reason_desc)                           AS common_return_reason,
  AVG(c.total_sales) FILTER (WHERE c.total_sales > 0) AS avg_sales_per_tx
FROM combined c
LEFT JOIN returns_agg r
  ON c.entity_id = CAST(r.s_store_id AS varchar) AND c.d_year = r.d_year
WHERE c.d_year >= 2000
  AND c.entity_id IS NOT NULL
  AND (c.total_sales IS NULL OR c.total_sales > 0)
  AND (c.total_net_profit IS NULL OR c.total_net_profit <> 0)
  AND (c.sales_transactions IS NOT NULL OR c.catalog_transactions IS NOT NULL)
GROUP BY c.entity_id, c.d_year, r.r_reason_desc
HAVING SUM(c.total_sales) > 50000
ORDER BY sum_net_profit DESC
LIMIT 100
