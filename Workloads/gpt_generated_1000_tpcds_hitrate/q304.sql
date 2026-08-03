WITH high_income_customers AS (
    SELECT c.c_customer_sk,
           c.c_customer_id
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 80000
)
SELECT
    hi.c_customer_id,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    'Catalog' AS sales_channel,
    CASE WHEN cs.cs_promo_sk IS NULL THEN 'No Promo' ELSE 'Promo' END AS promo_flag
FROM high_income_customers hi
JOIN catalog_sales cs ON cs.cs_bill_customer_sk = hi.c_customer_sk
GROUP BY
    hi.c_customer_id,
    CASE WHEN cs.cs_promo_sk IS NULL THEN 'No Promo' ELSE 'Promo' END

UNION ALL

SELECT
    hi.c_customer_id,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    'Web' AS sales_channel,
    CASE WHEN ws.ws_promo_sk IS NULL THEN 'No Promo' ELSE 'Promo' END AS promo_flag
FROM high_income_customers hi
JOIN web_sales ws ON ws.ws_bill_customer_sk = hi.c_customer_sk
GROUP BY
    hi.c_customer_id,
    CASE WHEN ws.ws_promo_sk IS NULL THEN 'No Promo' ELSE 'Promo' END

LIMIT 100
