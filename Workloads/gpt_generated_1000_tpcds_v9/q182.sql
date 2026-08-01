WITH agg_sales AS (
  SELECT
    cp.cp_department,
    cp.cp_catalog_page_sk,
    cp.cp_description,
    p.p_promo_name,
    cd.cd_gender,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS order_cnt
  FROM catalog_sales cs
  INNER JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  INNER JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  INNER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  INNER JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  WHERE
    cp.cp_catalog_page_sk IN (3, 5, 11)
    AND p.p_channel_event = 'N'
    AND p.p_channel_catalog = 'N'
    AND cs.cs_quantity > 2
    AND cs.cs_sales_price > 50.0
    AND cs.cs_ship_hdemo_sk IN (4418, 1645, 2593)
  GROUP BY
    cp.cp_department,
    cp.cp_catalog_page_sk,
    cp.cp_description,
    p.p_promo_name,
    cd.cd_gender
),
ranked_sales AS (
  SELECT
    cp_department,
    cp_catalog_page_sk,
    cp_description,
    p_promo_name,
    cd_gender,
    total_net_paid,
    total_net_profit,
    order_cnt,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_net_profit DESC) AS profit_rank,
    CASE WHEN total_net_profit > 10000 THEN 'High' ELSE 'Normal' END AS profit_flag
  FROM agg_sales
)
SELECT
  cp_department,
  cp_catalog_page_sk,
  cp_description,
  p_promo_name,
  cd_gender,
  total_net_paid,
  total_net_profit,
  order_cnt,
  profit_rank,
  profit_flag
FROM ranked_sales
WHERE profit_rank <= 10
ORDER BY total_net_profit DESC
LIMIT 100
