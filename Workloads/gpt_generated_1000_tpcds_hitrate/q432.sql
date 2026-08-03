WITH sales_with_details AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_hdemo_sk AS bill_hdemo_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        td.t_meal_time,
        hd.hd_buy_potential,
        hd.hd_income_band_sk
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ext_sales_price > 100
      AND td.t_meal_time LIKE 'dinner%'
      AND regexp_like(td.t_meal_time, '^dinner$|^dinner.*')
      AND hd.hd_buy_potential IS NOT NULL
),
avg_price_by_income AS (
    SELECT
        hd_income_band_sk,
        avg(cs_ext_sales_price) AS avg_price
    FROM sales_with_details
    GROUP BY hd_income_band_sk
)
SELECT
    DISTINCT swd.hd_buy_potential,
    swd.t_meal_time,
    SUM(swd.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS txn_count,
    AVG(swd.cs_ext_sales_price) AS avg_sale,
    (
        SELECT api.avg_price
        FROM avg_price_by_income api
        WHERE api.hd_income_band_sk = swd.hd_income_band_sk
    ) AS income_band_avg_price,
    ROW_NUMBER() OVER (PARTITION BY swd.hd_buy_potential ORDER BY SUM(swd.cs_ext_sales_price) DESC) AS rn
FROM sales_with_details swd
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN time_dim td_ret ON sr.sr_return_time_sk = td_ret.t_time_sk
    WHERE sr.sr_hdemo_sk = swd.bill_hdemo_sk
      AND td_ret.t_meal_time = swd.t_meal_time
      AND sr.sr_return_amt > 0
)
GROUP BY
    swd.hd_buy_potential,
    swd.t_meal_time,
    swd.hd_income_band_sk
ORDER BY total_sales DESC
LIMIT 100
