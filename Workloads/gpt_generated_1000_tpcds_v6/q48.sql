WITH sales AS (
    SELECT
        c.c_customer_id,
        c.c_last_name,
        hd.hd_income_band_sk,
        SUM(cs.cs_net_paid_inc_ship_tax) AS amount,
        COUNT(DISTINCT cs.cs_order_number) AS cnt
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk >= 10
      AND cs.cs_net_paid_inc_ship_tax > 2000
    GROUP BY c.c_customer_id, c.c_last_name, hd.hd_income_band_sk
),
returns AS (
    SELECT
        c.c_customer_id,
        c.c_last_name,
        hd.hd_income_band_sk,
        SUM(sr.sr_return_amt) AS amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk >= 10
      AND sr.sr_return_amt > 1500
    GROUP BY c.c_customer_id, c.c_last_name, hd.hd_income_band_sk
)
SELECT DISTINCT
    customer_id,
    last_name,
    income_band,
    activity,
    amount,
    cnt
FROM (
    SELECT
        c_customer_id AS customer_id,
        c_last_name AS last_name,
        hd_income_band_sk AS income_band,
        'sale'   AS activity,
        amount,
        cnt
    FROM sales
    UNION ALL
    SELECT
        c_customer_id AS customer_id,
        c_last_name AS last_name,
        hd_income_band_sk AS income_band,
        'return' AS activity,
        amount,
        cnt
    FROM returns
) AS combined
ORDER BY amount DESC, activity
