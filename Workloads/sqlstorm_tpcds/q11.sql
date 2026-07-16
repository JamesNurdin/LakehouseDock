SELECT
  d.d_year,
  d.d_month_seq,
  i.i_category,
  s.sales_channel,
  COUNT(*) AS order_count,
  SUM(s.quantity) AS total_quantity,
  SUM(s.net_paid) AS total_net_paid,
  SUM(s.net_profit) AS total_net_profit
FROM
  (
    SELECT
      ss_sold_date_sk AS sold_date_sk,
      ss_item_sk AS item_sk,
      ss_promo_sk AS promo_sk,
      ss_quantity AS quantity,
      ss_net_paid AS net_paid,
      ss_net_profit AS net_profit,
      'store' AS sales_channel
    FROM store_sales
    UNION ALL
    SELECT
      cs_sold_date_sk,
      cs_item_sk,
      cs_promo_sk,
      cs_quantity,
      cs_net_paid,
      cs_net_profit,
      'catalog' AS sales_channel
    FROM catalog_sales
    UNION ALL
    SELECT
      ws_sold_date_sk,
      ws_item_sk,
      ws_promo_sk,
      ws_quantity,
      ws_net_paid,
      ws_net_profit,
      'web' AS sales_channel
    FROM web_sales
  ) s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
JOIN promotion p ON s.promo_sk = p.p_promo_sk
WHERE d.d_year = 2002
  AND p.p_discount_active = 'Y'
GROUP BY
  d.d_year,
  d.d_month_seq,
  i.i_category,
  s.sales_channel
ORDER BY
  d.d_year,
  d.d_month_seq,
  i.i_category,
  s.sales_channel
