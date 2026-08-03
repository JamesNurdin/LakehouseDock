WITH sales_promotions AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_net_profit,
        p.p_promo_id,
        CASE
            WHEN cs.cs_net_profit > 0 THEN 'PROFIT'
            WHEN cs.cs_net_profit < 0 THEN 'LOSS'
            ELSE 'NO_SALES'
        END AS profit_flag
    FROM catalog_sales cs
    RIGHT OUTER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
),
eligible_customers AS (
    SELECT
        sp.cs_bill_customer_sk,
        sp.p_promo_id,
        sp.profit_flag
    FROM sales_promotions sp
    WHERE sp.cs_bill_customer_sk IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_refunded_customer_sk = sp.cs_bill_customer_sk
      )
)
SELECT ec.cs_bill_customer_sk AS customer_sk,
       ec.p_promo_id,
       ec.profit_flag,
       ib.ib_income_band_sk
FROM eligible_customers ec
JOIN customer c
    ON ec.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_upper_bound > 100000

UNION ALL

SELECT ec.cs_bill_customer_sk,
       ec.p_promo_id,
       ec.profit_flag,
       ib.ib_income_band_sk
FROM eligible_customers ec
JOIN customer c
    ON ec.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_upper_bound <= 100000

EXCEPT

SELECT c.c_customer_sk,
       NULL AS p_promo_id,
       NULL AS profit_flag,
       ib.ib_income_band_sk
FROM customer c
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
)

ORDER BY profit_flag, customer_sk
LIMIT 100
