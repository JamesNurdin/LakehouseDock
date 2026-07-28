WITH base AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_item_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_net_loss,
    d.d_year,
    i.i_brand,
    i.i_category,
    r.r_reason_desc,
    cc.cc_name,
    cp.cp_type,
    sm.sm_type AS ship_type,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    inv.inv_quantity_on_hand,
    p.p_promo_name,
    s.s_store_name,
    wp.wp_max_ad_count,
    cust.c_first_name,
    cd.cd_gender
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk AND p.p_start_date_sk <= d.d_date_sk AND p.p_end_date_sk >= d.d_date_sk
  LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
  LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk AND wp.wp_customer_sk = cust.c_customer_sk
  WHERE d.d_year = 2000
    AND i.i_brand = 'Brand#12'
    AND r.r_reason_desc LIKE '%Damaged%'
),
agg1 AS (
  SELECT
    d_year,
    i_brand,
    r_reason_desc,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_quantity) AS total_qty,
    AVG(cr_return_amount) AS avg_return_amount
  FROM base
  GROUP BY d_year, i_brand, r_reason_desc
)
SELECT *
FROM (
  SELECT
    d_year,
    i_brand,
    r_reason_desc,
    total_return_amount,
    total_qty,
    avg_return_amount,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_return_amount DESC) AS brand_return_rank
  FROM agg1
  WHERE total_return_amount > (SELECT AVG(total_return_amount) FROM agg1)

  UNION ALL

  SELECT
    d_year,
    i_brand,
    r_reason_desc,
    total_return_amount,
    total_qty,
    avg_return_amount,
    NULL AS brand_return_rank
  FROM agg1
  WHERE total_qty > 1000
) final_result
ORDER BY total_return_amount DESC
LIMIT 100
