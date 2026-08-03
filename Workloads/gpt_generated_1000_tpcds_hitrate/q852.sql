WITH filtered_returns AS (
  SELECT
    cr.cr_warehouse_sk,
    w.w_warehouse_name,
    w.w_city,
    d.d_year,
    d.d_month_seq,
    cr.cr_return_amount,
    cr.cr_net_loss,
    i.i_item_desc,
    sm.sm_type,
    hd.hd_income_band_sk,
    cr.cr_item_sk
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE regexp_like(i.i_item_desc, '(?i)er$')
    AND sm.sm_type LIKE '%DAY%'
    AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = cr.cr_item_sk
          AND inv.inv_warehouse_sk = cr.cr_warehouse_sk
          AND inv.inv_quantity_on_hand > 0
    )
),
agg_returns AS (
  SELECT
    fr.w_warehouse_name,
    fr.d_year,
    fr.d_month_seq,
    SUM(fr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS returns_cnt,
    MAX(fr.cr_return_amount) AS max_return_amount,
    (
      SELECT ib.ib_upper_bound
      FROM income_band ib
      JOIN household_demographics hd2 ON hd2.hd_income_band_sk = ib.ib_income_band_sk
      WHERE hd2.hd_demo_sk = fr.hd_income_band_sk
      ORDER BY ib.ib_upper_bound DESC
      FETCH FIRST 1 ROW ONLY
    ) AS top_income_upper,
    lc.city_prefix
  FROM filtered_returns fr
  CROSS JOIN LATERAL (
    SELECT substr(w.w_city, 1, 3) AS city_prefix
    FROM warehouse w
    WHERE w.w_warehouse_sk = fr.cr_warehouse_sk
  ) lc
  GROUP BY
    fr.w_warehouse_name,
    fr.d_year,
    fr.d_month_seq,
    lc.city_prefix,
    fr.hd_income_band_sk
)
SELECT
  a.w_warehouse_name,
  a.d_year,
  a.d_month_seq,
  a.total_net_loss,
  a.returns_cnt,
  a.max_return_amount,
  a.top_income_upper,
  a.city_prefix,
  SUM(a.total_net_loss) OVER (
    PARTITION BY a.w_warehouse_name
    ORDER BY a.d_year, a.d_month_seq
    ROWS UNBOUNDED PRECEDING
  ) AS running_net_loss
FROM agg_returns a
ORDER BY a.w_warehouse_name, a.d_year, a.d_month_seq
LIMIT 100
