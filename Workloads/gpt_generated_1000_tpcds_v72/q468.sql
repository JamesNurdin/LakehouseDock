WITH
  store_aggs AS (
    SELECT
      ib.ib_lower_bound AS lower_bound,
      ib.ib_upper_bound AS upper_bound,
      SUM(ss.ss_net_profit) AS total_profit,
      'store' AS sales_source
    FROM
      store_sales ss
      JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
      JOIN item i ON ss.ss_item_sk = i.i_item_sk
      LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE
      ss.ss_sold_date_sk BETWEEN 2450820 AND 2450830
    GROUP BY
      ib.ib_lower_bound,
      ib.ib_upper_bound
  ),
  catalog_aggs AS (
    SELECT
      ib.ib_lower_bound AS lower_bound,
      ib.ib_upper_bound AS upper_bound,
      SUM(cs.cs_net_profit) AS total_profit,
      'catalog' AS sales_source
    FROM
      catalog_sales cs
      JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
      LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
      cs.cs_sold_date_sk BETWEEN 2450820 AND 2450830
    GROUP BY
      ib.ib_lower_bound,
      ib.ib_upper_bound
  )
SELECT
  lower_bound,
  upper_bound,
  total_profit,
  sales_source
FROM
  store_aggs
UNION ALL
SELECT
  lower_bound,
  upper_bound,
  total_profit,
  sales_source
FROM
  catalog_aggs
ORDER BY
  total_profit DESC
LIMIT 100
