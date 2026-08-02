WITH base AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_ship_mode_sk,
    cs.cs_promo_sk,
    cs.cs_bill_customer_sk,
    d_sales.d_year,
    CASE WHEN d_sales.d_year >= 2001 THEN 'Y2K+' ELSE 'Pre2001' END AS period_category,
    i.i_brand,
    i.i_category,
    i.i_product_name,
    p.p_promo_name,
    p.p_discount_active AS p_discount_active,
    sm.sm_ship_mode_id,
    sm.sm_type AS sm_type,
    c.c_customer_sk,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    rs.r_reason_desc,
    inv.inv_quantity_on_hand,
    s.s_store_name,
    ws.web_name
  FROM catalog_sales cs
  JOIN date_dim d_sales
    ON cs.cs_sold_date_sk = d_sales.d_date_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN reason rs
    ON sr.sr_reason_sk = rs.r_reason_sk
  LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d_sales.d_date_sk
  LEFT JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d_sales.d_date_sk
  LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
)
SELECT
  period_category,
  i_brand,
  i_category,
  SUM(cs_quantity) AS total_quantity,
  SUM(cs_net_paid) AS total_net_paid,
  SUM(cs_net_profit) AS total_net_profit,
  COUNT(DISTINCT c_customer_id) AS distinct_customers,
  SUM(COALESCE(sr_return_quantity, 0)) AS total_store_return_qty,
  SUM(COALESCE(sr_return_amt, 0)) AS total_store_return_amt,
  SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_inventory_on_hand,
  AVG(ib_upper_bound - ib_lower_bound) AS avg_income_range
FROM base
WHERE
  d_year BETWEEN 2000 AND 2002
  AND i_brand = 'Brand#12'
  AND ib_lower_bound >= 50000
  AND sm_type = 'AIR'
  AND p_discount_active = 'Y'
  AND NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = base.cs_item_sk
      AND wr2.wr_refunded_customer_sk = base.c_customer_sk
  )
GROUP BY GROUPING SETS (
  (period_category, i_brand, i_category),
  (period_category, i_brand),
  (period_category),
  ()
)
ORDER BY period_category, i_brand, i_category
LIMIT 100
