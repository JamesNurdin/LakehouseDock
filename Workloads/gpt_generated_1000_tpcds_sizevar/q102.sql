WITH
  store_agg AS (
    SELECT
      ss_sold_date_sk,
      ss_item_sk,
      ss_promo_sk,
      ss_cdemo_sk,
      SUM(ss_net_profit) AS ss_net_profit_sum
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_item_sk, ss_promo_sk, ss_cdemo_sk
  ),
  catalog_agg AS (
    SELECT
      cs_sold_date_sk,
      cs_item_sk,
      cs_promo_sk,
      cs_bill_cdemo_sk,
      cs_call_center_sk,
      cs_catalog_page_sk,
      SUM(cs_net_profit) AS cs_net_profit_sum
    FROM catalog_sales
    GROUP BY cs_sold_date_sk, cs_item_sk, cs_promo_sk, cs_bill_cdemo_sk, cs_call_center_sk, cs_catalog_page_sk
  ),
  web_agg AS (
    SELECT
      ws_sold_date_sk,
      ws_item_sk,
      ws_promo_sk,
      ws_bill_cdemo_sk,
      SUM(ws_net_profit) AS ws_net_profit_sum
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk, ws_promo_sk, ws_bill_cdemo_sk
  )
SELECT
  d.d_date,
  i.i_item_id,
  i.i_product_name,
  p.p_promo_name,
  cd.cd_gender,
  cc.cc_name AS call_center_name,
  cp.cp_department,
  (store_agg.ss_net_profit_sum + catalog_agg.cs_net_profit_sum + web_agg.ws_net_profit_sum) AS total_net_profit,
  CASE WHEN p.p_channel_dmail = 'Y' THEN 'DirectMail' ELSE 'Other' END AS promo_channel_type,
  ROW_NUMBER() OVER (
    PARTITION BY d.d_year
    ORDER BY (store_agg.ss_net_profit_sum + catalog_agg.cs_net_profit_sum + web_agg.ws_net_profit_sum) DESC
  ) AS rank_year
FROM store_agg
JOIN date_dim d ON store_agg.ss_sold_date_sk = d.d_date_sk
JOIN item i ON store_agg.ss_item_sk = i.i_item_sk
JOIN promotion p ON store_agg.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON store_agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN catalog_agg ON catalog_agg.cs_sold_date_sk = d.d_date_sk
                 AND catalog_agg.cs_item_sk = i.i_item_sk
                 AND catalog_agg.cs_promo_sk = p.p_promo_sk
                 AND catalog_agg.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN call_center cc ON catalog_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON catalog_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_agg ON web_agg.ws_sold_date_sk = d.d_date_sk
            AND web_agg.ws_item_sk = i.i_item_sk
            AND web_agg.ws_promo_sk = p.p_promo_sk
            AND web_agg.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE
  d.d_year = 2000
  AND i.i_brand = 'Brand#23'
  AND p.p_discount_active = 'Y'
  AND cd.cd_gender = 'F'
  AND (store_agg.ss_net_profit_sum + catalog_agg.cs_net_profit_sum + web_agg.ws_net_profit_sum) > (
    SELECT AVG(ss_net_profit) FROM store_sales
  )
ORDER BY
  d.d_date ASC,
  (store_agg.ss_net_profit_sum + catalog_agg.cs_net_profit_sum + web_agg.ws_net_profit_sum) DESC
LIMIT 100
