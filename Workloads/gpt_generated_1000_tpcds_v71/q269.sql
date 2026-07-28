WITH sales_agg AS (
  SELECT
    i.i_item_sk,
    i.i_category,
    i.i_brand,
    i.i_class,
    i.i_product_name,
    c.c_customer_sk,
    hd.hd_buy_potential,
    ib.ib_upper_bound AS income_upper,
    cs.cs_ext_sales_price,
    cs.cs_net_profit
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
),
returns_agg AS (
  SELECT
    i.i_item_sk,
    wr.wr_return_amt,
    r.r_reason_desc,
    wp.wp_url,
    c_ret.c_customer_sk AS returning_customer_sk,
    hd_ret.hd_buy_potential AS returning_buy_potential,
    ib_ret.ib_upper_bound AS returning_income_upper
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN customer c_ret ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
  JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN income_band ib_ret ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
)
SELECT
  sa.i_category,
  sa.i_brand,
  sa.i_class,
  sa.i_product_name,
  sa.hd_buy_potential,
  sa.income_upper,
  SUM(sa.cs_ext_sales_price) AS total_sales,
  SUM(COALESCE(ra.wr_return_amt, 0)) AS total_returns,
  SUM(sa.cs_net_profit) - SUM(COALESCE(ra.wr_return_amt, 0)) AS net_profit,
  RANK() OVER (ORDER BY SUM(sa.cs_net_profit) - SUM(COALESCE(ra.wr_return_amt, 0)) DESC) AS profit_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra ON sa.i_item_sk = ra.i_item_sk
GROUP BY
  sa.i_category,
  sa.i_brand,
  sa.i_class,
  sa.i_product_name,
  sa.hd_buy_potential,
  sa.income_upper
ORDER BY net_profit DESC
LIMIT 100
