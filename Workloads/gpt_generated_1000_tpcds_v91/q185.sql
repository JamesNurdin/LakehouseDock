WITH promo_details AS (
  SELECT
    p.p_promo_sk,
    p.p_promo_name,
    p.p_channel_details,
    SPLIT(p.p_channel_details, ',') AS detail_arr,
    p.p_start_date_sk,
    p.p_end_date_sk
  FROM promotion p
  WHERE REGEXP_LIKE(p.p_channel_details, '(local|National)')
)
SELECT
  d.d_year,
  pd.p_promo_name,
  t.detail AS detail_token,
  REGEXP_EXTRACT(t.detail, '(\\w+)', 1) AS first_word_detail,
  CONCAT(pd.p_promo_name, ': ', TRIM(t.detail)) AS promo_detail_concat,
  COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
  SUM(ss.ss_net_paid) AS total_net_paid,
  SUM(ss.ss_net_profit) AS total_net_profit,
  CASE
    WHEN SUM(ss.ss_net_profit) > 20000 THEN 'High'
    WHEN SUM(ss.ss_net_profit) > 0 THEN 'Medium'
    ELSE 'Low'
  END AS profit_category,
  (
    SELECT AVG(ss2.ss_net_profit)
    FROM store_sales ss2
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = d.d_year
  ) AS avg_yearly_net_profit
FROM promo_details pd
JOIN store_sales ss
  ON ss.ss_promo_sk = pd.p_promo_sk
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
CROSS JOIN UNNEST(pd.detail_arr) AS t(detail)
WHERE d.d_year = 2002
  AND REGEXP_LIKE(i.i_product_name, '[A-Z]{3}')
  AND i.i_product_name LIKE '%-%'
  AND EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_ticket_number = ss.ss_ticket_number
  )
GROUP BY d.d_year, pd.p_promo_name, t.detail
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
