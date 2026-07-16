WITH sales_union AS (
  SELECT ss.ss_sold_date_sk AS sold_date_sk,
         ss.ss_item_sk AS item_sk,
         ss.ss_quantity AS quantity,
         ss.ss_ext_discount_amt AS discount_amt,
         ss.ss_net_paid AS net_paid,
         ss.ss_net_profit AS net_profit,
         'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT cs.cs_sold_date_sk,
         cs.cs_item_sk,
         cs.cs_quantity,
         cs.cs_ext_discount_amt,
         cs.cs_net_paid,
         cs.cs_net_profit,
         'catalog'
  FROM catalog_sales cs
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_item_sk,
         ws.ws_quantity,
         ws.ws_ext_discount_amt,
         ws.ws_net_paid,
         ws.ws_net_profit,
         'web'
  FROM web_sales ws
),
sales_enriched AS (
  SELECT su.*,
         d.d_year,
         d.d_month_seq,
         i.i_brand,
         i.i_class,
         i.i_category
  FROM sales_union su
  JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
  JOIN item i ON su.item_sk = i.i_item_sk
  WHERE d.d_year = 2001
),
agg AS (
  SELECT
    d_year,
    d_month_seq,
    i_brand,
    i_class,
    i_category,
    channel,
    SUM(quantity) AS total_quantity,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    SUM(discount_amt) AS total_discount
  FROM sales_enriched
  GROUP BY GROUPING SETS (
    (d_year, d_month_seq, i_brand, i_class, i_category, channel),
    (d_year, d_month_seq, i_brand, i_class, i_category),
    (d_year, d_month_seq, i_brand, i_class),
    (d_year, d_month_seq, i_brand),
    (d_year, d_month_seq)
  )
)
SELECT
  d_year,
  d_month_seq,
  i_brand,
  i_class,
  i_category,
  channel,
  total_quantity,
  total_net_paid,
  total_net_profit,
  total_discount,
  rn AS rank_in_month
FROM (
  SELECT
    d_year,
    d_month_seq,
    i_brand,
    i_class,
    i_category,
    channel,
    total_quantity,
    total_net_paid,
    total_net_profit,
    total_discount,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_paid DESC) AS rn
  FROM agg
  WHERE channel IS NOT NULL
    AND i_brand IS NOT NULL
    AND i_class IS NOT NULL
    AND i_category IS NOT NULL
) t
WHERE rn <= 10
ORDER BY d_year, d_month_seq, rn
LIMIT 100
