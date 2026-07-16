WITH sales_agg AS (
  SELECT
    i.i_brand AS brand,
    cd.cd_gender AS gender,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cs.cs_ext_sales_price > 1000
    AND cs.cs_bill_hdemo_sk IN (2606, 6696)
    AND cs.cs_ship_addr_sk IN (5184251, 2121279)
  GROUP BY i.i_brand, cd.cd_gender
),
returns_agg AS (
  SELECT
    i.i_brand AS brand,
    cd.cd_gender AS gender,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    COUNT(*) AS returns_cnt
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE sr.sr_return_amt > 0
    AND sr.sr_return_quantity > 0
    AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2459999
  GROUP BY i.i_brand, cd.cd_gender
)
SELECT
  s.brand,
  s.gender,
  s.total_net_profit,
  r.total_return_amt,
  (s.total_net_profit - COALESCE(r.total_return_amt, 0)) AS net_profit_after_returns,
  s.sales_cnt,
  COALESCE(r.returns_cnt, 0) AS returns_cnt,
  CASE WHEN s.sales_cnt > 0 THEN s.total_net_profit / s.sales_cnt ELSE NULL END AS avg_profit_per_sale,
  CASE WHEN COALESCE(r.returns_cnt, 0) > 0 THEN r.total_return_amt / r.returns_cnt ELSE NULL END AS avg_return_amt_per_return
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.brand = r.brand
  AND s.gender = r.gender
ORDER BY net_profit_after_returns DESC
LIMIT 50
