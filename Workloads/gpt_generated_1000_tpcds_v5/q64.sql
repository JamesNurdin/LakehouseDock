WITH
  sr AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      i.i_category,
      i.i_brand,
      hd.hd_buy_potential,
      ib.ib_lower_bound,
      ca.ca_state
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_quantity > 10
      AND sr.sr_return_amt > 20
      AND i.i_current_price BETWEEN 5 AND 500
      AND ib.ib_upper_bound <= 100000
  ),
  cr AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      i.i_category,
      i.i_brand,
      hd.hd_buy_potential,
      ib.ib_lower_bound,
      ca.ca_state,
      cc.cc_name,
      cp.cp_catalog_number
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cr.cr_return_quantity > 10
      AND cr.cr_return_amount > 20
      AND i.i_current_price BETWEEN 5 AND 500
      AND cc.cc_gmt_offset >= -5
  ),
  union_all AS (
    SELECT
      item_sk,
      return_quantity,
      return_amount,
      category,
      brand,
      buy_potential,
      lower_income,
      state,
      call_center_name,
      catalog_number
    FROM (
      SELECT
        sr.sr_item_sk AS item_sk,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_return_amt AS return_amount,
        sr.i_category AS category,
        sr.i_brand AS brand,
        sr.hd_buy_potential AS buy_potential,
        sr.ib_lower_bound AS lower_income,
        sr.ca_state AS state,
        CAST(NULL AS varchar) AS call_center_name,
        CAST(NULL AS integer) AS catalog_number
      FROM sr
      UNION ALL
      SELECT
        cr.cr_item_sk AS item_sk,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_amount AS return_amount,
        cr.i_category AS category,
        cr.i_brand AS brand,
        cr.hd_buy_potential AS buy_potential,
        cr.ib_lower_bound AS lower_income,
        cr.ca_state AS state,
        cr.cc_name AS call_center_name,
        cr.cp_catalog_number AS catalog_number
      FROM cr
    )
  ),
  agg AS (
    SELECT
      category,
      brand,
      AVG(return_quantity) AS avg_qty,
      SUM(return_amount) AS total_amount,
      COUNT(*) AS cnt,
      SUM(CASE WHEN call_center_name IS NOT NULL THEN 1 ELSE 0 END) AS cnt_cc
    FROM union_all
    WHERE lower_income >= 20000
      AND state IN ('CA', 'TX', 'NY')
    GROUP BY category, brand
    HAVING SUM(return_amount) > 1000
  )
SELECT
  category,
  brand,
  avg_qty,
  total_amount,
  cnt,
  cnt_cc,
  CASE WHEN cnt_cc > 0 THEN total_amount / cnt_cc ELSE NULL END AS avg_amount_per_cc,
  (SELECT MAX(cc_gmt_offset) FROM call_center) AS max_cc_offset
FROM agg
WHERE avg_qty > 5
ORDER BY total_amount DESC
LIMIT 100
