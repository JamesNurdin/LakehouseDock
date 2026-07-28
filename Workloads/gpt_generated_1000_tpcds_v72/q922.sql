WITH cs AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.cs_sold_time_sk,
    cs.cs_item_sk,
    cs.cs_promo_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_ship_cdemo_sk,
    cs.cs_catalog_page_sk,
    cp.cp_department,
    cp.cp_catalog_number,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    t.t_hour,
    cd.cd_gender,
    cd.cd_education_status
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cp.cp_catalog_number BETWEEN 10 AND 30
    AND i.i_size = 'medium'
    AND p.p_discount_active = 'Y'
    AND t.t_hour BETWEEN 8 AND 20
    AND cd.cd_gender = 'F'
),
ws AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_profit,
    ws.ws_sold_time_sk,
    ws.ws_item_sk,
    ws.ws_promo_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_ship_cdemo_sk,
    ws.ws_web_site_sk,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    t.t_hour,
    cd.cd_gender,
    cd.cd_education_status
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE i.i_size = 'medium'
    AND p.p_discount_active = 'Y'
    AND t.t_hour BETWEEN 8 AND 20
    AND cd.cd_gender = 'F'
    AND EXISTS (
      SELECT 1 FROM web_site w
      WHERE w.web_site_sk = ws.ws_web_site_sk
        AND w.web_country = 'USA'
    )
),
aggregated AS (
  SELECT
    category,
    brand,
    promo_name,
    hour,
    SUM(net_profit) AS total_net_profit,
    COUNT(*) AS txn_count
  FROM (
    SELECT
      i_category AS category,
      i_brand AS brand,
      p_promo_name AS promo_name,
      t_hour AS hour,
      cs_net_profit AS net_profit
    FROM cs
    UNION ALL
    SELECT
      i_category,
      i_brand,
      p_promo_name,
      t_hour,
      ws_net_profit
    FROM ws
  ) u
  GROUP BY GROUPING SETS (
    (category, brand, promo_name, hour),
    (category, brand, promo_name),
    (category, brand),
    (category)
  )
  HAVING SUM(net_profit) > 1000
)
SELECT
  category,
  brand,
  promo_name,
  hour,
  total_net_profit,
  txn_count,
  RANK() OVER (PARTITION BY category ORDER BY total_net_profit DESC) AS profit_rank_in_category
FROM aggregated
ORDER BY category, total_net_profit DESC
LIMIT 100
