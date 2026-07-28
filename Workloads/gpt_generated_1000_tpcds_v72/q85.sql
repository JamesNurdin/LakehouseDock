WITH store_sales_cte AS (
  SELECT
    c.c_customer_sk,
    c.c_last_name,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(*) AS order_count,
    CASE WHEN MIN(p.p_discount_active) = 'Y' THEN 'Promo' ELSE 'NoPromo' END AS promo_flag
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE t.t_hour BETWEEN 9 AND 17
    AND NOT EXISTS (
      SELECT 1 FROM store_returns sr
      WHERE sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    )
  GROUP BY c.c_customer_sk, c.c_last_name, p.p_discount_active
),

web_sales_cte AS (
  SELECT
    c.c_customer_sk,
    c.c_last_name,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(*) AS order_count,
    CASE WHEN MIN(p.p_discount_active) = 'Y' THEN 'Promo' ELSE 'NoPromo' END AS promo_flag
  FROM web_sales ws
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE t.t_hour BETWEEN 9 AND 17
    AND NOT EXISTS (
      SELECT 1 FROM web_returns wr
      WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_order_number = ws.ws_order_number
    )
  GROUP BY c.c_customer_sk, c.c_last_name, p.p_discount_active
),

combined AS (
  SELECT * FROM store_sales_cte
  UNION ALL
  SELECT * FROM web_sales_cte
),

final AS (
  SELECT
    DISTINCT c_customer_sk,
    c_last_name,
    total_net_paid,
    order_count,
    promo_flag,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS sales_rank,
    CASE WHEN total_net_paid > (SELECT AVG(total_net_paid) FROM combined) THEN 'AboveAvg' ELSE 'BelowAvg' END AS performance_category
  FROM combined
)

SELECT
  c_customer_sk,
  c_last_name,
  total_net_paid,
  order_count,
  promo_flag,
  sales_rank,
  performance_category
FROM final
WHERE sales_rank <= 100
ORDER BY sales_rank
LIMIT 100
