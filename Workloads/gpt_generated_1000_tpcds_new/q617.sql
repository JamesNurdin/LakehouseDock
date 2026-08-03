WITH sampled_customers AS (
    SELECT c_customer_sk,
           c_current_hdemo_sk,
           c_birth_year,
           c_birth_day,
           c_last_review_date
    FROM customer
    TABLESAMPLE BERNOULLI (10)
),
agg_union AS (
    SELECT ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           hd.hd_buy_potential,
           COUNT(DISTINCT sc.c_customer_sk) AS cust_cnt
    FROM sampled_customers sc
    JOIN household_demographics hd
      ON sc.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sc.c_birth_year BETWEEN 1970 AND 1990
      AND hd.hd_buy_potential = '5001-10000'
    GROUP BY CUBE (ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential)

    UNION ALL

    SELECT ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           hd.hd_buy_potential,
           COUNT(DISTINCT sc.c_customer_sk) AS cust_cnt
    FROM sampled_customers sc
    JOIN household_demographics hd
      ON sc.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sc.c_birth_year BETWEEN 1991 AND 2000
      AND hd.hd_buy_potential = '1001-5000'
    GROUP BY CUBE (ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential)
),
demog_agg AS (
    SELECT hd.hd_buy_potential,
           COUNT(DISTINCT sc.c_customer_sk) AS other_cust_cnt
    FROM sampled_customers sc
    JOIN household_demographics hd
      ON sc.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 2
    GROUP BY hd.hd_buy_potential
)
SELECT u.ib_lower_bound,
       u.ib_upper_bound,
       u.hd_buy_potential,
       u.cust_cnt,
       d.other_cust_cnt,
       ROW_NUMBER() OVER (PARTITION BY u.ib_income_band_sk ORDER BY u.cust_cnt DESC) AS rank_in_income_band
FROM agg_union u
FULL OUTER JOIN demog_agg d
  ON u.hd_buy_potential = d.hd_buy_potential
ORDER BY u.cust_cnt DESC NULLS LAST,
         u.hd_buy_potential
LIMIT 100
