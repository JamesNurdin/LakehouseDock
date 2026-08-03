WITH sampled_store_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
    ),
    customer_agg AS (
        SELECT
            c.c_customer_id,
            c.c_customer_sk,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
            (
                SELECT COUNT(DISTINCT p.p_promo_sk)
                FROM promotion p
                JOIN sampled_store_sales ss2 ON ss2.ss_promo_sk = p.p_promo_sk
                WHERE ss2.ss_customer_sk = c.c_customer_sk
            ) AS distinct_promotions_used
        FROM sampled_store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ib.ib_lower_bound >= 50000
        GROUP BY c.c_customer_id, c.c_customer_sk
    ),
    purchase_set AS (
        SELECT
            ca.c_customer_id,
            ca.total_sales,
            ca.profit_category,
            ca.distinct_promotions_used,
            ib.ib_income_band_sk
        FROM customer_agg ca
        CROSS JOIN (
            SELECT ib_income_band_sk
            FROM income_band
            WHERE ib_upper_bound <= 80000
            LIMIT 1
        ) ib
    ),
    return_set AS (
        SELECT
            c.c_customer_id,
            SUM(cr.cr_return_amount) AS total_sales,
            CASE WHEN SUM(cr.cr_fee) > 0 THEN 'High' ELSE 'Low' END AS profit_category,
            0 AS distinct_promotions_used,
            ib.ib_income_band_sk
        FROM catalog_returns cr
        JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ib.ib_lower_bound >= 50000
        GROUP BY c.c_customer_id, ib.ib_income_band_sk
    )
SELECT *
FROM purchase_set
EXCEPT
SELECT *
FROM return_set
ORDER BY total_sales DESC
LIMIT 100
