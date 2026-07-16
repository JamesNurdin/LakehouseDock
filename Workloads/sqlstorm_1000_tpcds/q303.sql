WITH unified_sales AS (
  SELECT ss_sold_date_sk AS sold_date_sk,
         'store' AS channel,
         ss_net_paid AS net_paid,
         ss_net_profit AS net_profit,
         ss_item_sk AS item_sk,
         ss_promo_sk AS promo_sk
  FROM store_sales
  UNION ALL
  SELECT cs_sold_date_sk,
         'catalog',
         cs_net_paid,
         cs_net_profit,
         cs_item_sk,
         cs_promo_sk
  FROM catalog_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         'web',
         ws_net_paid,
         ws_net_profit,
         ws_item_sk,
         ws_promo_sk
  FROM web_sales
)
SELECT d.d_year,
       i.i_category,
       us.channel,
       sum(us.net_paid) AS total_net_paid,
       sum(us.net_profit) AS total_net_profit,
       count(*) AS sales_transactions,
       sum(CASE WHEN p.p_discount_active = 'Y' THEN us.net_paid ELSE 0 END) AS discounted_net_paid
FROM unified_sales us
JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year, i.i_category, us.channel
ORDER BY d.d_year, total_net_paid DESC
LIMIT 200
