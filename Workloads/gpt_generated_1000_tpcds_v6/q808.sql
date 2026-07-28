WITH filtered_returns AS (
   SELECT
       cr_returned_date_sk,
       cr_returned_time_sk,
       cr_item_sk,
       cr_refunded_customer_sk,
       cr_refunded_hdemo_sk,
       cr_return_quantity,
       cr_return_amount,
       cr_refunded_cash,
       cr_return_amt_inc_tax,
       cr_fee
   FROM tpcds.catalog_returns
   WHERE cr_return_quantity > 0
     AND cr_return_amount BETWEEN 10 AND 5000
     AND cr_refunded_cash > 100
     AND cr_fee <= 50
     AND cr_returned_date_sk BETWEEN 2450000 AND 2451500
     AND cr_returned_time_sk BETWEEN 0 AND 86400
),
joined_hd AS (
   SELECT
       fr.*,
       hd.hd_demo_sk,
       hd.hd_income_band_sk,
       hd.hd_buy_potential,
       hd.hd_dep_count,
       hd.hd_vehicle_count
   FROM filtered_returns fr
   JOIN tpcds.household_demographics hd
     ON fr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE hd.hd_dep_count BETWEEN 1 AND 8
     AND hd.hd_buy_potential IN ('HIGH', 'MEDIUM')
),
joined_all AS (
   SELECT
       jh.*,
       ib.ib_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound
   FROM joined_hd jh
   JOIN tpcds.income_band ib
     ON jh.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ib.ib_upper_bound >= 30000
     AND ib.ib_lower_bound <= 120000
)
SELECT
    cr_returned_date_sk,
    cr_returned_time_sk,
    cr_item_sk,
    cr_refunded_cash,
    cr_return_amount,
    hd_buy_potential,
    hd_dep_count,
    hd_vehicle_count,
    ib_lower_bound,
    ib_upper_bound,
    ROW_NUMBER() OVER (PARTITION BY ib_income_band_sk ORDER BY cr_refunded_cash DESC) AS cash_rank,
    CASE
        WHEN cr_refunded_cash > 5000 THEN 'Very High'
        WHEN cr_refunded_cash > 2000 THEN 'High'
        WHEN cr_refunded_cash > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS cash_category
FROM joined_all
WHERE cr_return_amount IS NOT NULL
ORDER BY ib_income_band_sk, cash_rank
LIMIT 100
