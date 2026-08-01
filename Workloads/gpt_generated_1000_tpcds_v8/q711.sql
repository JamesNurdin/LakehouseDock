WITH
-- Store sales aggregated per customer with a lateral subquery that fetches the maximum promotion cost for the sale
store_agg AS (
    SELECT
        ss.ss_customer_sk                AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid_inc_tax)      AS total_spent,
        promo.max_discount
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    CROSS JOIN LATERAL (
        SELECT MAX(p.p_cost) AS max_discount
        FROM tpcds.promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
    ) AS promo
    WHERE ss.ss_net_paid_inc_tax > 1000
      AND ib.ib_lower_bound >= 50000
    GROUP BY ss.ss_customer_sk, c.c_first_name, c.c_last_name, promo.max_discount
    HAVING SUM(ss.ss_net_paid_inc_tax) > 2000
),
store_part AS (
    SELECT
        customer_sk,
        c_first_name,
        c_last_name,
        total_spent,
        ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY total_spent DESC) AS rank,
        max_discount
    FROM store_agg
),
-- Web sales aggregated per customer with a similar lateral subquery
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk          AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_spent,
        promo.max_discount
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    CROSS JOIN LATERAL (
        SELECT MAX(p.p_cost) AS max_discount
        FROM tpcds.promotion p
        WHERE p.p_promo_sk = ws.ws_promo_sk
    ) AS promo
    WHERE ws.ws_net_paid_inc_ship_tax > 1500
      AND ib.ib_lower_bound >= 50000
    GROUP BY ws.ws_bill_customer_sk, c.c_first_name, c.c_last_name, promo.max_discount
    HAVING SUM(ws.ws_net_paid_inc_ship_tax) > 3000
),
web_part AS (
    SELECT
        customer_sk,
        c_first_name,
        c_last_name,
        total_spent,
        ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY total_spent DESC) AS rank,
        max_discount
    FROM web_agg
),
-- Combine store and web customers (set operation UNION ALL)
combined AS (
    SELECT * FROM store_part
    UNION ALL
    SELECT * FROM web_part
),
-- Customers that have at least one catalog return, but exclude those that appear in a specific reason code (anti‑semi‑join)
eligible_returns AS (
    SELECT DISTINCT cr.cr_refunded_customer_sk AS customer_sk
    FROM tpcds.catalog_returns cr
    WHERE cr.cr_refunded_customer_sk NOT IN (
        SELECT cr2.cr_returning_customer_sk
        FROM tpcds.catalog_returns cr2
        WHERE cr2.cr_reason_sk = 9999
    )
),
-- Intersect the two key sets (customers from sales with customers that have eligible returns)
final_customers AS (
    SELECT customer_sk FROM combined
    INTERSECT
    SELECT customer_sk FROM eligible_returns
)
SELECT
    fc.customer_sk,
    c.c_first_name,
    c.c_last_name,
    fc.total_spent,
    fc.rank,
    fc.max_discount
FROM (
    SELECT *
    FROM combined
    WHERE customer_sk IN (SELECT customer_sk FROM final_customers)
) fc
JOIN tpcds.customer c
    ON fc.customer_sk = c.c_customer_sk
ORDER BY fc.total_spent DESC, fc.rank ASC
LIMIT 100
