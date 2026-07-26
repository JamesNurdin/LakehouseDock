WITH catalog_customer AS (
  SELECT
    cs.cs_bill_customer_sk AS customer_sk,
    SUM(cs.cs_net_profit) AS catalog_profit,
    MIN(d.d_date) AS first_catalog_date
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  GROUP BY cs.cs_bill_customer_sk
),
web_customer AS (
  SELECT
    ws.ws_bill_customer_sk AS customer_sk,
    SUM(ws.ws_net_profit) AS web_profit,
    MIN(d.d_date) AS first_web_date
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  GROUP BY ws.ws_bill_customer_sk
),
page_visits AS (
  SELECT
    wp.wp_customer_sk AS customer_sk,
    COUNT(DISTINCT wp.wp_web_page_sk) AS page_visits
  FROM web_page wp
  GROUP BY wp.wp_customer_sk
)
SELECT
  COALESCE(c.customer_sk, w.customer_sk) AS customer_sk,
  COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0) AS total_profit,
  LEAST(
    COALESCE(c.first_catalog_date, DATE '9999-12-31'),
    COALESCE(w.first_web_date, DATE '9999-12-31')
  ) AS first_purchase_date,
  CASE
    WHEN COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0) < 1000 THEN 'Low'
    WHEN COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0) BETWEEN 1000 AND 10000 THEN 'Medium'
    ELSE 'High'
  END AS profit_tier,
  COALESCE(p.page_visits, 0) AS page_visits,
  ROW_NUMBER() OVER (
    PARTITION BY
      CASE
        WHEN COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0) < 1000 THEN 'Low'
        WHEN COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0) BETWEEN 1000 AND 10000 THEN 'Medium'
        ELSE 'High'
      END
    ORDER BY COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0) DESC
  ) AS tier_rank
FROM catalog_customer c
FULL OUTER JOIN web_customer w ON c.customer_sk = w.customer_sk
LEFT JOIN page_visits p ON COALESCE(c.customer_sk, w.customer_sk) = p.customer_sk
WHERE COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0) > 0
ORDER BY total_profit DESC
LIMIT 20
