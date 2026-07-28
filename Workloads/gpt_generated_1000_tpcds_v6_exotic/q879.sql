WITH store_data AS (
    SELECT
        c.c_customer_id,
        ss.ss_net_paid AS net_paid,
        ib.ib_upper_bound AS income_upper,
        (
            SELECT MAX(p.p_cost)
            FROM promotion p
            WHERE p.p_promo_sk = ss.ss_promo_sk
        ) AS max_promo_cost
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
      AND EXISTS (
          SELECT 1 FROM promotion p
          WHERE p.p_promo_sk = ss.ss_promo_sk
            AND p.p_discount_active = 'Y'
      )
),
web_data AS (
    SELECT
        c.c_customer_id,
        ws.ws_net_paid AS net_paid,
        ib.ib_upper_bound AS income_upper,
        (
            SELECT MAX(p.p_cost)
            FROM promotion p
            WHERE p.p_promo_sk = ws.ws_promo_sk
        ) AS max_promo_cost
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
      AND EXISTS (
          SELECT 1 FROM promotion p
          WHERE p.p_promo_sk = ws.ws_promo_sk
            AND p.p_discount_active = 'Y'
      )
),
combined AS (
    SELECT c_customer_id, net_paid, income_upper, max_promo_cost, 'store' AS channel
    FROM store_data
    UNION ALL
    SELECT c_customer_id, net_paid, income_upper, max_promo_cost, 'web' AS channel
    FROM web_data
),
agg AS (
    SELECT
        c_customer_id,
        SUM(net_paid) AS total_net_paid,
        MAX(income_upper) AS income_upper,
        MAX(max_promo_cost) AS max_promo_cost,
        COUNT(*) AS transaction_count
    FROM combined
    GROUP BY c_customer_id
    HAVING SUM(net_paid) > 1000
)
SELECT
    c_customer_id,
    total_net_paid,
    income_upper,
    max_promo_cost,
    transaction_count,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS revenue_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
