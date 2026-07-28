WITH sales AS (
    SELECT
        'Store' AS category,
        s.s_store_name AS detail,
        CAST(SUM(ss.ss_ext_sales_price) AS decimal(15,2)) AS amount,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rank
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_discount_active = 'Y'
      AND cd.cd_credit_rating = 'Good'
    GROUP BY s.s_store_name, s.s_store_id
),
returns AS (
    SELECT
        'IncomeBand' AS category,
        CONCAT(CAST(ib.ib_lower_bound AS VARCHAR), '-', CAST(ib.ib_upper_bound AS VARCHAR)) AS detail,
        CAST(SUM(cr.cr_return_amount) AS decimal(15,2)) AS amount,
        ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS rank
    FROM catalog_returns cr
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound <= 150000
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT category, detail, amount, rank
FROM sales
UNION ALL
SELECT category, detail, amount, rank
FROM returns
ORDER BY amount DESC, rank ASC
LIMIT 100
