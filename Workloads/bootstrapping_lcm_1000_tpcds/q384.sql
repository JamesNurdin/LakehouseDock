WITH promo_sales AS (
  SELECT
    d_sales.d_year AS sales_year,
    s.s_store_name AS store_name,
    s.s_city AS city,
    s.s_geography_class AS geography_class,
    p.p_discount_active AS discount_active,
    ss.ss_ticket_number,
    ss.ss_net_paid,
    ss.ss_ext_discount_amt,
    ss.ss_net_profit
  FROM store_sales ss
  JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
  LEFT JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
  LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
  WHERE d_sales.d_year BETWEEN 2015 AND 2020
    AND (d_closed.d_date_sk IS NULL OR d_closed.d_date > CURRENT_DATE)
),
aggregated AS (
  SELECT
    sales_year,
    store_name,
    city,
    geography_class,
    COUNT(DISTINCT ss_ticket_number) AS num_tickets,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_ext_discount_amt) AS total_discount,
    AVG(ss_net_profit) AS avg_net_profit,
    SUM(CASE WHEN discount_active = 'Y' THEN ss_ext_discount_amt ELSE 0 END) / NULLIF(SUM(ss_ext_discount_amt), 0) AS discount_active_ratio
  FROM promo_sales
  GROUP BY
    sales_year,
    store_name,
    city,
    geography_class
  HAVING COUNT(DISTINCT ss_ticket_number) > 100
)
SELECT
  sales_year,
  store_name,
  city,
  geography_class,
  num_tickets,
  total_net_paid,
  total_discount,
  avg_net_profit,
  discount_active_ratio,
  ROW_NUMBER() OVER (PARTITION BY sales_year ORDER BY avg_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY sales_year, profit_rank
LIMIT 100
