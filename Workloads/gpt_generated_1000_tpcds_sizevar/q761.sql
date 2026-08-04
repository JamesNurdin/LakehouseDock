WITH
-- 1) Base fact: store_sales sampled
ss_base AS (
    SELECT ss_sold_date_sk,
           ss_sold_time_sk,
           ss_customer_sk,
           ss_promo_sk,
           ss_ticket_number,
           ss_sales_price,
           ss_net_paid,
           ss_net_profit
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)      -- sample 10% of rows
),
-- Join promotion, customer, time_dim, store_returns and reason (star around store_sales)
ss_joined AS (
    SELECT ss.*, p.p_promo_name, p.p_discount_active,
           c.c_first_name, c.c_last_name, c.c_preferred_cust_flag,
           t.t_hour, t.t_minute, t.t_second,
           sr.sr_return_amt, sr.sr_fee, r.r_reason_desc
    FROM ss_base ss
    JOIN promotion p   ON ss.ss_promo_sk   = p.p_promo_sk
    JOIN customer  c   ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim  t   ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r        ON sr.sr_reason_sk   = r.r_reason_sk
),
-- Correlated scalar sub‑query : total web sales paid by the same customer
ss_enhanced AS (
    SELECT s.*, 
           (SELECT SUM(ws.ws_net_paid)
            FROM web_sales ws
            WHERE ws.ws_bill_customer_sk = s.ss_customer_sk) AS web_customer_total_paid,
           rn.rand_val
    FROM ss_joined s
    CROSS JOIN (SELECT 1 AS rand_val UNION ALL SELECT 2 UNION ALL SELECT 3) rn
    WHERE s.ss_sales_price > 20
      AND s.ss_net_profit BETWEEN -100 AND 500
      AND s.t_hour BETWEEN 8 AND 20
      AND s.c_preferred_cust_flag = 'Y'
      AND (s.p_discount_active = 'Y' OR s.p_discount_active IS NULL)
),
-- Aggregation with GROUPING SETS for the store_sales branch
ss_agg AS (
    SELECT ss_sold_date_sk,
           r_reason_desc,
           SUM(ss_sales_price)               AS total_sales_price,
           AVG(ss_net_profit)                AS avg_net_profit,
           COUNT(DISTINCT c_first_name)      AS distinct_customers,
           SUM(web_customer_total_paid)      AS total_web_paid,
           GROUPING(ss_sold_date_sk)         AS g_date,
           GROUPING(r_reason_desc)           AS g_reason
    FROM ss_enhanced
    GROUP BY GROUPING SETS (
        (ss_sold_date_sk, r_reason_desc),
        (ss_sold_date_sk),
        (r_reason_desc)
    )
    HAVING SUM(ss_sales_price) > 1000
),

-- 2) Second fact: catalog_sales sampled, joined to catalog_page, promotion, customer, time_dim
cs_base AS (
    SELECT cs_sold_date_sk,
           cs_sold_time_sk,
           cs_bill_customer_sk,
           cs_catalog_page_sk,
           cs_promo_sk,
           cs_sales_price,
           cs_quantity
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (5)       -- sample 5% of rows
),
cs_joined AS (
    SELECT cs.*, cp.cp_department, cp.cp_catalog_number,
           p.p_promo_name, p.p_discount_active,
           c.c_first_name, c.c_last_name, c.c_preferred_cust_flag,
           t.t_hour, t.t_minute
    FROM cs_base cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p     ON cs.cs_promo_sk      = p.p_promo_sk
    JOIN customer c      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t      ON cs.cs_sold_time_sk = t.t_time_sk
),
-- Correlated scalar sub‑query : total web returns amount for the same customer
cs_enhanced AS (
    SELECT cs.*, 
           (SELECT SUM(wr.wr_return_amt)
            FROM web_returns wr
            WHERE wr.wr_refunded_customer_sk = cs.cs_bill_customer_sk) AS total_web_return_amt,
           rn2.rand_val
    FROM cs_joined cs
    CROSS JOIN (SELECT 1 AS rand_val UNION ALL SELECT 2) rn2
    WHERE cs.cs_sales_price > 30
      AND cs.t_hour BETWEEN 9 AND 18
      AND cs.c_preferred_cust_flag = 'Y'
      AND cs.cp_department IS NOT NULL
),
-- Aggregation with GROUPING SETS for the catalog_sales branch
cs_agg AS (
    SELECT cs_sold_date_sk,
           cp_department,
           SUM(cs_sales_price)          AS total_sales_price,
           AVG(cs_quantity)             AS avg_quantity,
           COUNT(DISTINCT c_first_name) AS distinct_customers,
           SUM(total_web_return_amt)    AS total_web_returns,
           GROUPING(cs_sold_date_sk)    AS g_date,
           GROUPING(cp_department)      AS g_dept
    FROM cs_enhanced
    GROUP BY GROUPING SETS (
        (cs_sold_date_sk, cp_department),
        (cs_sold_date_sk),
        (cp_department)
    )
    HAVING SUM(cs_sales_price) > 800
)
-- Final result: UNION DISTINCT of the two aggregated sets
SELECT ss_sold_date_sk   AS sold_date_sk,
       r_reason_desc    AS grouping_key,
       total_sales_price,
       avg_net_profit,
       distinct_customers,
       total_web_paid   AS extra_metric,
       g_date,
       g_reason
FROM ss_agg
UNION DISTINCT
SELECT cs_sold_date_sk   AS sold_date_sk,
       cp_department     AS grouping_key,
       total_sales_price,
       avg_quantity      AS avg_net_profit,
       distinct_customers,
       total_web_returns AS extra_metric,
       g_date,
       g_dept            AS g_reason
FROM cs_agg
ORDER BY total_sales_price DESC
LIMIT 100
