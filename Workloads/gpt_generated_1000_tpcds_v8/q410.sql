WITH
  sales_agg AS (
    SELECT
      ws_bill_customer_sk,
      SUM(ws_net_profit) AS total_profit,
      COUNT(*) AS orders_cnt,
      MAX(ws_sold_date_sk) AS last_sold_date_sk
    FROM web_sales ws
    WHERE EXISTS (
      SELECT 1 FROM promotion p
      WHERE p.p_promo_sk = ws.ws_promo_sk
        AND p.p_channel_email = 'Y'
    )
    GROUP BY ws_bill_customer_sk
  ),

  cust_info AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_email_address,
      ca.ca_county,
      ca.ca_gmt_offset,
      cd.cd_gender,
      hd.hd_buy_potential
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  ),

  intersect_keys AS (
    SELECT ws_bill_customer_sk
    FROM web_sales
    WHERE ws_net_profit > 5000
    INTERSECT
    SELECT c_customer_sk
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
  ),

  combined AS (
    SELECT
      ci.c_customer_sk,
      ci.c_first_name,
      ci.c_last_name,
      ci.c_email_address,
      ci.ca_county,
      ci.hd_buy_potential,
      sa.total_profit,
      sa.orders_cnt,
      sa.last_sold_date_sk
    FROM sales_agg sa
    FULL OUTER JOIN cust_info ci
      ON sa.ws_bill_customer_sk = ci.c_customer_sk
    WHERE ci.ca_county IS NOT NULL
      AND regexp_like(ci.ca_county, 'County$')
      AND regexp_like(ci.c_email_address, '^.*@example\\.com$')
      AND ci.c_customer_sk IN (SELECT ws_bill_customer_sk FROM intersect_keys)
  )

SELECT DISTINCT
  combined.c_customer_sk,
  combined.c_first_name || ' ' || combined.c_last_name AS full_name,
  regexp_extract(combined.c_email_address, '@(.+)$', 1) AS email_domain,
  combined.ca_county,
  combined.hd_buy_potential,
  combined.total_profit,
  combined.orders_cnt,
  ROW_NUMBER() OVER (PARTITION BY combined.hd_buy_potential ORDER BY combined.total_profit DESC) AS rank_in_potential,
  SUM(combined.total_profit) OVER (PARTITION BY combined.hd_buy_potential ORDER BY combined.total_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_profit,
  (SELECT AVG(total_profit) FROM sales_agg) AS avg_total_profit
FROM combined
WHERE combined.total_profit > (SELECT AVG(total_profit) FROM sales_agg)
  AND combined.orders_cnt > (SELECT AVG(orders_cnt) FROM sales_agg)

UNION ALL

SELECT DISTINCT
  c.c_customer_sk,
  c.c_first_name || ' ' || c.c_last_name AS full_name,
  regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
  ca.ca_county,
  hd.hd_buy_potential,
  ws_sum.total_profit,
  ws_sum.orders_cnt,
  ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY ws_sum.total_profit DESC) AS rank_in_potential,
  SUM(ws_sum.total_profit) OVER (PARTITION BY hd.hd_buy_potential ORDER BY ws_sum.total_profit DESC ROWS UNBOUNDED PRECEDING) AS running_profit,
  (SELECT AVG(total_profit) FROM sales_agg) AS avg_total_profit
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN (
  SELECT ws_bill_customer_sk, SUM(ws_net_profit) AS total_profit, COUNT(*) AS orders_cnt
  FROM web_sales
  GROUP BY ws_bill_customer_sk
) ws_sum ON ws_sum.ws_bill_customer_sk = c.c_customer_sk
WHERE ca.ca_county LIKE '%County'
  AND c.c_email_address LIKE '%@example.com'

ORDER BY total_profit DESC
LIMIT 100
