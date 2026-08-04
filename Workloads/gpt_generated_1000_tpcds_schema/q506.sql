WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_ticket_number
    FROM store_sales ss
    WHERE ss.ss_sales_price > 20.00
      AND ss.ss_quantity BETWEEN 1 AND 5
      AND ss.ss_customer_sk IN (
          SELECT DISTINCT ss2.ss_customer_sk
          FROM store_sales ss2
          WHERE ss2.ss_ext_discount_amt > 0
      )
),
union_sales AS (
    SELECT ss.* FROM base_sales ss
    UNION
    SELECT ss.* FROM base_sales ss WHERE ss.ss_ext_sales_price < 500
),
joined_full AS (
    SELECT
        us.*, 
        td.t_hour,
        td.t_minute,
        td.t_second,
        td.t_meal_time
    FROM union_sales us
    FULL OUTER JOIN time_dim td
        ON us.ss_sold_time_sk = td.t_time_sk
)
SELECT
    ca.ca_state,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT jf.ss_ticket_number) AS transaction_cnt,
    SUM(jf.ss_ext_sales_price) AS total_sales,
    AVG(jf.ss_net_profit) AS avg_profit,
    MIN(jf.ss_sales_price) AS min_price,
    MAX(jf.ss_sales_price) AS max_price,
    jf.t_hour,
    jf.t_minute,
    jf.t_second,
    jf.t_meal_time
FROM joined_full jf
LEFT JOIN customer_address ca
    ON jf.ss_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
    ON jf.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
    ON jf.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
  AND ib.ib_upper_bound >= 80000
GROUP BY
    ca.ca_state,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    jf.t_hour,
    jf.t_minute,
    jf.t_second,
    jf.t_meal_time
ORDER BY total_sales DESC
LIMIT 100
