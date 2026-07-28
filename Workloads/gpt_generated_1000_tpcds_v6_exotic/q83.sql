WITH
  cat AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_promo_sk,
      cs.cs_bill_cdemo_sk AS cdemo_sk,
      cs.cs_ext_sales_price AS ext_sales_price,
      cs.cs_net_profit AS net_profit,
      cs.cs_quantity AS quantity,
      'catalog' AS channel
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 100
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451200
  ),
  web AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_promo_sk,
      ws.ws_bill_cdemo_sk AS cdemo_sk,
      ws.ws_ext_sales_price AS ext_sales_price,
      ws.ws_net_profit AS net_profit,
      ws.ws_quantity AS quantity,
      'web' AS channel
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 100
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451200
  ),
  joined AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      p.p_promo_name,
      cd.cd_education_status,
      s.channel,
      s.ext_sales_price AS sales_price,
      s.net_profit,
      s.quantity
    FROM cat s
    JOIN item i ON s.cs_item_sk = i.i_item_sk
    JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON s.cdemo_sk = cd.cd_demo_sk
    WHERE i.i_units = 'Dozen'
      AND cd.cd_education_status IN ('Primary', 'Secondary', '4 yr Degree')
    UNION ALL
    SELECT
      i.i_item_id,
      i.i_product_name,
      p.p_promo_name,
      cd.cd_education_status,
      s.channel,
      s.ext_sales_price AS sales_price,
      s.net_profit,
      s.quantity
    FROM web s
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    JOIN promotion p ON s.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON s.cdemo_sk = cd.cd_demo_sk
    WHERE i.i_units = 'Dozen'
      AND cd.cd_education_status IN ('Primary', 'Secondary', '4 yr Degree')
  )
SELECT DISTINCT
  i_item_id,
  i_product_name,
  p_promo_name,
  cd_education_status,
  channel,
  sales_price,
  net_profit,
  quantity,
  ROW_NUMBER() OVER (PARTITION BY channel ORDER BY net_profit DESC) AS profit_rank,
  SUM(sales_price) OVER (PARTITION BY i_item_id ORDER BY sales_price DESC
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales_price,
  AVG(net_profit) OVER (PARTITION BY channel ORDER BY sales_price
                         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_profit
FROM joined
WHERE sales_price > (SELECT AVG(cs_ext_sales_price) FROM catalog_sales)
ORDER BY profit_rank
LIMIT 100
