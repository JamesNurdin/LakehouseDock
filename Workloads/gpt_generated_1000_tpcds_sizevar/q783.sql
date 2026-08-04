/* Goal: Analyze yearly net profit by promotion, counting unique customers and summarizing profit metrics for sales in 2001 dinner time, while integrating returns, catalog information, and web sales, and retaining unmatched dimension rows. */
WITH intersect_keys AS (
    SELECT ss.ss_customer_sk AS cust_sk
    FROM store_sales ss
    INTERSECT
    SELECT cr.cr_refunded_customer_sk
    FROM catalog_returns cr
),
ss AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
cr AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
),
sr AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
),
ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    d.d_year,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(CASE WHEN ss.ss_coupon_amt > 500 THEN ss.ss_coupon_amt ELSE 0 END) AS avg_high_coupon,
    MAX(ss.ss_net_profit) AS max_net_profit,
    MIN(ss.ss_net_profit) AS min_net_profit
FROM ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
FULL OUTER JOIN sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
RIGHT OUTER JOIN cr
  ON ss.ss_item_sk = cr.cr_item_sk
FULL OUTER JOIN ws
  ON ss.ss_ticket_number = ws.ws_order_number
FULL OUTER JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
FULL OUTER JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN intersect_keys ik
  ON ss.ss_customer_sk = ik.cust_sk
WHERE d.d_year = 2001
  AND t.t_meal_time = 'dinner'
  AND p.p_discount_active = 'Y'
  AND cd.cd_gender = 'M'
  AND hd.hd_buy_potential = '5000-9999'
  AND cp.cp_department = 'Electronics'
  AND ss.ss_net_profit > (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        WHERE ss2.ss_sold_date_sk = d.d_date_sk
    )
GROUP BY d.d_year, p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
