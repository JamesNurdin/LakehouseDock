WITH
    catalog_agg AS (
        SELECT
            hd.hd_income_band_sk,
            SUM(cs.cs_net_paid) AS cat_sum_net_paid,
            COUNT(*) AS cat_cnt
        FROM catalog_sales cs
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        WHERE cs.cs_wholesale_cost > 50
          AND cs.cs_ship_date_sk BETWEEN 2450830 AND 2450900
          AND cs.cs_quantity >= 1
          AND cs.cs_net_paid IS NOT NULL
        GROUP BY hd.hd_income_band_sk
    ),
    store_agg AS (
        SELECT
            hd.hd_income_band_sk,
            SUM(ss.ss_net_paid_inc_tax) AS store_sum_net_paid_inc_tax,
            COUNT(*) AS store_cnt
        FROM store_sales ss
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        WHERE ss.ss_ext_wholesale_cost > 500
          AND ss.ss_net_paid_inc_tax < 5000
          AND ss.ss_quantity BETWEEN 1 AND 10
          AND ss.ss_net_paid_inc_tax IS NOT NULL
        GROUP BY hd.hd_income_band_sk
    ),
    full_join AS (
        SELECT
            COALESCE(ca.hd_income_band_sk, sa.hd_income_band_sk) AS hd_income_band_sk,
            ca.cat_sum_net_paid,
            ca.cat_cnt,
            sa.store_sum_net_paid_inc_tax,
            sa.store_cnt
        FROM catalog_agg ca
        FULL OUTER JOIN store_agg sa
            ON ca.hd_income_band_sk = sa.hd_income_band_sk
    ),
    intersect_keys AS (
        SELECT hd_income_band_sk FROM catalog_agg
        INTERSECT
        SELECT hd_income_band_sk FROM store_agg
    ),
    final_agg AS (
        SELECT
            fj.hd_income_band_sk,
            COALESCE(fj.cat_sum_net_paid, 0) + COALESCE(fj.store_sum_net_paid_inc_tax, 0) AS total_paid,
            CASE
                WHEN (COALESCE(fj.cat_sum_net_paid, 0) + COALESCE(fj.store_sum_net_paid_inc_tax, 0)) > 20000 THEN 'High'
                ELSE 'Low'
            END AS payment_category,
            fj.cat_cnt,
            fj.store_cnt
        FROM full_join fj
        WHERE fj.hd_income_band_sk NOT IN (
            SELECT hd_income_band_sk
            FROM household_demographics
            WHERE hd_buy_potential = 'Unknown'
        )
          AND fj.hd_income_band_sk IN (SELECT hd_income_band_sk FROM intersect_keys)
    )
SELECT
    payment_category,
    COUNT(*) AS num_income_bands,
    SUM(total_paid) AS sum_total_paid,
    AVG(total_paid) AS avg_total_paid
FROM final_agg
GROUP BY payment_category
HAVING SUM(total_paid) > 50000
ORDER BY sum_total_paid DESC
LIMIT 100
