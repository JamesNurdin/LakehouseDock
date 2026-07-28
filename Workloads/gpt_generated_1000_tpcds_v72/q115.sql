WITH
  sales_data AS (
    SELECT
      cs.cs_sold_date_sk AS sold_date_sk,
      cs.cs_bill_customer_sk AS customer_sk,
      cs.cs_bill_hdemo_sk AS hdemo_sk,
      cs.cs_promo_sk AS promo_sk,
      cs.cs_net_paid AS net_paid,
      cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_bill_customer_sk,
      ws.ws_bill_hdemo_sk,
      ws.ws_promo_sk,
      ws.ws_net_paid,
      ws.ws_net_profit
    FROM web_sales ws
  ),
  customer_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_email_address,
      regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
      substring(c.c_first_name, 1, 1) || '.' || c.c_last_name AS short_name,
      c.c_birth_country
    FROM customer c
  ),
  joined AS (
    SELECT
      s.sold_date_sk,
      s.net_paid,
      s.net_profit,
      p.p_promo_name,
      p.p_channel_details,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      ca.email_domain,
      ca.short_name
    FROM sales_data s
    JOIN promotion p ON s.promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON s.hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_agg ca ON s.customer_sk = ca.c_customer_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
      AND p.p_channel_details LIKE '%online%'
      AND ca.email_domain LIKE '%.com'
  )
SELECT
  email_domain,
  p_promo_name,
  SUM(net_profit) AS total_profit,
  COUNT(*) AS transaction_cnt,
  ROW_NUMBER() OVER (PARTITION BY email_domain ORDER BY SUM(net_profit) DESC) AS profit_rank,
  CONCAT(short_name, '@', email_domain) AS contact_info
FROM joined
GROUP BY email_domain, p_promo_name, short_name
ORDER BY total_profit DESC
LIMIT 100
