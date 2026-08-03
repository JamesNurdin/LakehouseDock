WITH sales_union AS (
  SELECT
    p.p_promo_id,
    d.d_year,
    cd.cd_gender,
    ss.ss_net_profit AS net_profit,
    ss.ss_customer_sk AS customer_key
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year BETWEEN 2001 AND 2003
    AND cd.cd_gender = 'M'
    AND p.p_channel_email = 'N'
    AND p.p_discount_active = 'Y'
  UNION ALL
  SELECT
    p.p_promo_id,
    d.d_year,
    cd.cd_gender,
    ws.ws_net_profit AS net_profit,
    ws.ws_bill_customer_sk AS customer_key
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year BETWEEN 2001 AND 2003
    AND cd.cd_gender = 'M'
    AND p.p_channel_email = 'N'
    AND p.p_discount_active = 'Y'
),
promo_year AS (
  SELECT
    p_promo_id,
    d_year,
    SUM(net_profit) AS yearly_profit,
    COUNT(DISTINCT customer_key) AS uniq_customers
  FROM sales_union
  GROUP BY p_promo_id, d_year
),
promo_summary AS (
  SELECT
    p_promo_id,
    AVG(yearly_profit) AS avg_yearly_profit,
    SUM(uniq_customers) AS total_customers
  FROM promo_year
  GROUP BY p_promo_id
  HAVING AVG(yearly_profit) > 10000
),
promo_excluded AS (
  SELECT
    p_promo_id
  FROM promo_year
  GROUP BY p_promo_id
  HAVING AVG(yearly_profit) < 5000
)
SELECT
  p.p_promo_id,
  p.p_promo_name,
  ps.avg_yearly_profit,
  ps.total_customers
FROM promo_summary ps
JOIN promotion p ON ps.p_promo_id = p.p_promo_id
EXCEPT
SELECT
  p.p_promo_id,
  p.p_promo_name,
  ps.avg_yearly_profit,
  ps.total_customers
FROM promo_excluded pe
JOIN promotion p ON pe.p_promo_id = p.p_promo_id
JOIN (
  SELECT
    p_promo_id,
    AVG(yearly_profit) AS avg_yearly_profit,
    SUM(uniq_customers) AS total_customers
  FROM promo_year
  GROUP BY p_promo_id
) ps ON ps.p_promo_id = p.p_promo_id
ORDER BY avg_yearly_profit DESC
LIMIT 100
