WITH catalog_agg AS (
  SELECT i.i_category AS i_category,
         d.d_year AS d_year,
         d.d_moy AS d_moy,
         SUM(cs.cs_net_profit) AS profit,
         SUM(cs.cs_ext_discount_amt) AS discount,
         COUNT(*) AS order_cnt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_year = 2001
    AND i.i_size = 'M'
    AND cd.cd_gender = 'F'
    AND cp.cp_type = 'monthly'
  GROUP BY i.i_category, d.d_year, d.d_moy
),
store_agg AS (
  SELECT i.i_category AS i_category,
         d.d_year AS d_year,
         d.d_moy AS d_moy,
         SUM(ss.ss_net_profit) AS profit,
         SUM(ss.ss_ext_discount_amt) AS discount,
         COUNT(*) AS order_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year = 2001
    AND i.i_size = 'M'
    AND cd.cd_gender = 'F'
  GROUP BY i.i_category, d.d_year, d.d_moy
),
web_agg AS (
  SELECT i.i_category AS i_category,
         d.d_year AS d_year,
         d.d_moy AS d_moy,
         SUM(ws.ws_net_profit) AS profit,
         SUM(ws.ws_ext_discount_amt) AS discount,
         COUNT(*) AS order_cnt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year = 2001
    AND i.i_size = 'M'
    AND cd.cd_gender = 'F'
  GROUP BY i.i_category, d.d_year, d.d_moy
)
SELECT
  COALESCE(ca.i_category, sa.i_category, wa.i_category) AS category,
  COALESCE(ca.d_year, sa.d_year, wa.d_year) AS year,
  COALESCE(ca.d_moy, sa.d_moy, wa.d_moy) AS month,
  COALESCE(ca.profit, 0) AS catalog_profit,
  COALESCE(sa.profit, 0) AS store_profit,
  COALESCE(wa.profit, 0) AS web_profit,
  COALESCE(ca.discount, 0) AS catalog_discount,
  COALESCE(sa.discount, 0) AS store_discount,
  COALESCE(wa.discount, 0) AS web_discount,
  COALESCE(ca.order_cnt, 0) AS catalog_orders,
  COALESCE(sa.order_cnt, 0) AS store_orders,
  COALESCE(wa.order_cnt, 0) AS web_orders,
  (COALESCE(ca.profit,0) + COALESCE(sa.profit,0) + COALESCE(wa.profit,0)) AS total_profit,
  (COALESCE(ca.discount,0) + COALESCE(sa.discount,0) + COALESCE(wa.discount,0)) AS total_discount,
  (COALESCE(ca.order_cnt,0) + COALESCE(sa.order_cnt,0) + COALESCE(wa.order_cnt,0)) AS total_orders,
  RANK() OVER (ORDER BY (COALESCE(ca.profit,0) + COALESCE(sa.profit,0) + COALESCE(wa.profit,0)) DESC) AS profit_rank
FROM catalog_agg ca
FULL OUTER JOIN store_agg sa
  ON ca.i_category = sa.i_category
 AND ca.d_year = sa.d_year
 AND ca.d_moy = sa.d_moy
FULL OUTER JOIN web_agg wa
  ON COALESCE(ca.i_category, sa.i_category) = wa.i_category
 AND COALESCE(ca.d_year, sa.d_year) = wa.d_year
 AND COALESCE(ca.d_moy, sa.d_moy) = wa.d_moy
WHERE (COALESCE(ca.profit,0) + COALESCE(sa.profit,0) + COALESCE(wa.profit,0)) > 10000
ORDER BY total_profit DESC
LIMIT 50
