WITH cr_sales AS (
   SELECT
     ib.ib_lower_bound,
     ib.ib_upper_bound,
     hd.hd_buy_potential,
     cr.cr_net_loss,
     cs.cs_net_profit,
     cs.cs_ext_sales_price,
     cs.cs_quantity
   FROM catalog_returns cr
   JOIN catalog_sales cs
     ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
   JOIN household_demographics hd
     ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
wr_returns AS (
   SELECT
     ib.ib_lower_bound,
     ib.ib_upper_bound,
     hd.hd_buy_potential,
     wr.wr_net_loss
   FROM web_returns wr
   JOIN household_demographics hd
     ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
  ib_lower_bound,
  ib_upper_bound,
  hd_buy_potential,
  SUM(cr_net_loss) AS total_catalog_return_net_loss,
  SUM(wr_net_loss) AS total_web_return_net_loss,
  SUM(cs_net_profit) AS total_catalog_sales_net_profit,
  SUM(cs_ext_sales_price) AS total_catalog_sales_ext_sales,
  SUM(cs_quantity) AS total_catalog_sales_quantity
FROM (
   SELECT
     ib_lower_bound,
     ib_upper_bound,
     hd_buy_potential,
     cr_net_loss,
     CAST(NULL AS DECIMAL(7,2)) AS wr_net_loss,
     cs_net_profit,
     cs_ext_sales_price,
     cs_quantity
   FROM cr_sales
   UNION ALL
   SELECT
     ib_lower_bound,
     ib_upper_bound,
     hd_buy_potential,
     CAST(NULL AS DECIMAL(7,2)) AS cr_net_loss,
     wr_net_loss,
     CAST(NULL AS DECIMAL(7,2)) AS cs_net_profit,
     CAST(NULL AS DECIMAL(7,2)) AS cs_ext_sales_price,
     CAST(NULL AS INTEGER) AS cs_quantity
   FROM wr_returns
) t
GROUP BY ib_lower_bound, ib_upper_bound, hd_buy_potential
ORDER BY ib_lower_bound, hd_buy_potential
