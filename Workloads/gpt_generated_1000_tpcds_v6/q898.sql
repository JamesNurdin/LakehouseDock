WITH store_agg AS (
  SELECT
    p.p_promo_id,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    COUNT(DISTINCT ss.ss_customer_sk) AS store_customers
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE d.d_year = 2001
    AND t.t_hour BETWEEN 9 AND 17
    AND c.c_preferred_cust_flag = 'Y'
    AND p.p_channel_tv = 'N'
    AND p.p_discount_active = 'Y'
  GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
web_agg AS (
  SELECT
    p.p_promo_id,
    d.d_year,
    d.d_month_seq,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customers
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE d.d_year = 2001
    AND sm.sm_carrier = 'UPS'
    AND sm.sm_contract LIKE 'Xjy3ZPui%'
    AND ws.ws_ext_list_price > 1000
    AND p.p_channel_radio = 'N'
    AND p.p_discount_active = 'Y'
  GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
avg_store_profit AS (
  SELECT AVG(ss2.ss_net_profit) AS avg_profit
  FROM store_sales ss2
  JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
  WHERE d2.d_year = 2001
)
SELECT
  sa.p_promo_id,
  sa.d_year,
  sa.d_month_seq,
  sa.store_profit,
  wa.web_profit,
  (sa.store_profit + wa.web_profit) AS total_profit,
  (sa.store_sales + wa.web_sales) AS total_sales,
  (sa.store_customers + wa.web_customers) AS total_customers,
  (sa.store_profit + wa.web_profit) / NULLIF((sa.store_customers + wa.web_customers), 0) AS profit_per_customer,
  avgp.avg_profit
FROM store_agg sa
JOIN web_agg wa
  ON sa.p_promo_id = wa.p_promo_id
 AND sa.d_year = wa.d_year
 AND sa.d_month_seq = wa.d_month_seq
CROSS JOIN avg_store_profit avgp
WHERE (sa.store_profit + wa.web_profit) > avgp.avg_profit * 2
ORDER BY total_profit DESC
LIMIT 100
