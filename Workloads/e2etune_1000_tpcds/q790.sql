WITH cs_agg AS (
  SELECT
    i.i_category,
    i.i_brand,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_credit_rating = 'A'
    AND cd.cd_education_status = 'College'
    AND cs.cs_sold_date_sk BETWEEN 2459580 AND 2459670
  GROUP BY i.i_category, i.i_brand
),
ws_agg AS (
  SELECT
    i.i_category,
    i.i_brand,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(*) AS sales_cnt
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_credit_rating = 'A'
    AND cd.cd_education_status = 'College'
    AND ws.ws_sold_date_sk BETWEEN 2459580 AND 2459670
  GROUP BY i.i_category, i.i_brand
),
combined AS (
  SELECT
    COALESCE(cs.i_category, ws.i_category) AS i_category,
    COALESCE(cs.i_brand, ws.i_brand) AS i_brand,
    COALESCE(cs.total_net_profit, 0) + COALESCE(ws.total_net_profit, 0) AS total_net_profit,
    COALESCE(cs.total_discount, 0) + COALESCE(ws.total_discount, 0) AS total_discount,
    COALESCE(cs.total_quantity, 0) + COALESCE(ws.total_quantity, 0) AS total_quantity,
    COALESCE(cs.sales_cnt, 0) + COALESCE(ws.sales_cnt, 0) AS sales_cnt
  FROM cs_agg cs
  FULL OUTER JOIN ws_agg ws
    ON cs.i_category = ws.i_category AND cs.i_brand = ws.i_brand
)
SELECT
  i_category,
  i_brand,
  total_net_profit,
  total_discount,
  total_quantity,
  sales_cnt,
  ROUND(total_discount / NULLIF(total_quantity, 0), 2) AS avg_discount_per_item,
  RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM combined
WHERE total_net_profit > 10000
ORDER BY profit_rank
LIMIT 10
