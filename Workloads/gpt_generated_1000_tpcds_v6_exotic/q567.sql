WITH
  catalog_part AS (
    SELECT
      'catalog' AS source,
      promotion.p_promo_name AS promo_name,
      promotion.p_channel_event AS channel,
      regexp_extract(promotion.p_promo_id, '[0-9]+') AS promo_code,
      CAST(NULL AS varchar) AS page_type,
      CASE WHEN catalog_sales.cs_net_profit >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
      catalog_sales.cs_net_profit AS total_amount
    FROM tpcds.catalog_sales AS catalog_sales
    JOIN tpcds.promotion AS promotion
      ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
    JOIN tpcds.customer AS customer
      ON catalog_sales.cs_bill_customer_sk = customer.c_customer_sk
    WHERE regexp_like(promotion.p_promo_name, '(?i)discount|sale')
      AND promotion.p_cost > 0
      AND promotion.p_channel_event = 'N'
  ),
  web_part AS (
    SELECT
      'web' AS source,
      CAST(NULL AS varchar) AS promo_name,
      CAST(NULL AS varchar) AS channel,
      CAST(NULL AS varchar) AS promo_code,
      web_page.wp_type AS page_type,
      CASE WHEN web_returns.wr_net_loss >= 0 THEN 'Loss' ELSE 'Profit' END AS profit_category,
      web_returns.wr_net_loss AS total_amount
    FROM tpcds.web_returns AS web_returns
    JOIN tpcds.web_page AS web_page
      ON web_returns.wr_web_page_sk = web_page.wp_web_page_sk
    JOIN tpcds.customer AS customer
      ON web_returns.wr_refunded_customer_sk = customer.c_customer_sk
    WHERE web_page.wp_url LIKE '%example.com%'
      AND regexp_like(web_page.wp_type, '^A')
      AND web_page.wp_char_count > 0
  ),
  combined AS (
    SELECT * FROM catalog_part
    UNION ALL
    SELECT * FROM web_part
  )
SELECT
  source,
  promo_name,
  channel,
  promo_code,
  page_type,
  profit_category,
  SUM(total_amount) AS total_amount
FROM combined
GROUP BY GROUPING SETS (
  (source, promo_name, channel, promo_code, page_type, profit_category),
  (source, promo_name, channel, promo_code, profit_category),
  (source, page_type, profit_category),
  (source, profit_category),
  (source)
)
ORDER BY source, total_amount DESC
LIMIT 100
