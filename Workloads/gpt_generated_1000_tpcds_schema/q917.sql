WITH
  sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),

  full_joined AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_item_sk,
      cs.cs_promo_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_ship_mode_sk,
      cs.cs_net_paid_inc_tax,
      cs.cs_quantity,
      p.p_promo_name,
      p.p_item_sk
    FROM sampled_sales cs
    FULL OUTER JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
  ),

  joined AS (
    SELECT
      fj.cs_sold_date_sk,
      fj.cs_item_sk,
      fj.cs_promo_sk,
      fj.cs_bill_hdemo_sk,
      fj.cs_ship_mode_sk,
      fj.cs_net_paid_inc_tax,
      fj.cs_quantity,
      fj.p_promo_name,
      i.i_category,
      i.i_brand,
      i.i_product_name,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      sm.sm_carrier
    FROM full_joined fj
    LEFT JOIN item i
      ON COALESCE(fj.cs_item_sk, fj.p_item_sk) = i.i_item_sk
    LEFT JOIN household_demographics hd
      ON fj.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN ship_mode sm
      ON fj.cs_ship_mode_sk = sm.sm_ship_mode_sk
  ),

  aggregated AS (
    SELECT
      i_category,
      i_brand,
      CONCAT(i_brand, '-', i_category) AS brand_category,
      REGEXP_LIKE(i_product_name, '(?i)pro') AS product_has_pro,
      REGEXP_EXTRACT(p_promo_name, '(\\w+)', 1) AS promo_first_word,
      CASE WHEN sm_carrier LIKE '%DHL%' THEN 'DHL' ELSE 'Other' END AS carrier_type,
      ib_lower_bound,
      ib_upper_bound,
      SUM(cs_net_paid_inc_tax) AS total_paid,
      COUNT(*) AS sales_cnt,
      ROW_NUMBER() OVER (ORDER BY SUM(cs_net_paid_inc_tax) DESC) AS global_row_num
    FROM joined
    GROUP BY
      i_category,
      i_brand,
      i_product_name,
      p_promo_name,
      sm_carrier,
      ib_lower_bound,
      ib_upper_bound
  )
SELECT
  *,
  LAG(total_paid) OVER (PARTITION BY brand_category ORDER BY total_paid DESC) AS lag_total_paid
FROM aggregated
ORDER BY total_paid DESC
LIMIT 100
