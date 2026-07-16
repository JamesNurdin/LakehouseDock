SELECT
    date_dim.d_year,
    'store' AS channel,
    customer_demographics.cd_gender,
    income_band.ib_lower_bound,
    income_band.ib_upper_bound,
    SUM(store_sales.ss_net_profit) AS net_profit
FROM store_sales
JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
JOIN customer ON store_sales.ss_customer_sk = customer.c_customer_sk
JOIN customer_demographics ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
JOIN household_demographics ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
WHERE date_dim.d_year BETWEEN 2000 AND 2002
GROUP BY date_dim.d_year,
         customer_demographics.cd_gender,
         income_band.ib_lower_bound,
         income_band.ib_upper_bound

UNION ALL

SELECT
    date_dim.d_year,
    'catalog' AS channel,
    customer_demographics.cd_gender,
    income_band.ib_lower_bound,
    income_band.ib_upper_bound,
    SUM(catalog_sales.cs_net_profit) AS net_profit
FROM catalog_sales
JOIN date_dim ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
JOIN customer ON catalog_sales.cs_bill_customer_sk = customer.c_customer_sk
JOIN customer_demographics ON catalog_sales.cs_bill_cdemo_sk = customer_demographics.cd_demo_sk
JOIN household_demographics ON catalog_sales.cs_bill_hdemo_sk = household_demographics.hd_demo_sk
JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
WHERE date_dim.d_year BETWEEN 2000 AND 2002
GROUP BY date_dim.d_year,
         customer_demographics.cd_gender,
         income_band.ib_lower_bound,
         income_band.ib_upper_bound

UNION ALL

SELECT
    date_dim.d_year,
    'web' AS channel,
    customer_demographics.cd_gender,
    income_band.ib_lower_bound,
    income_band.ib_upper_bound,
    SUM(web_sales.ws_net_profit) AS net_profit
FROM web_sales
JOIN date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
JOIN customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
JOIN customer_demographics ON web_sales.ws_bill_cdemo_sk = customer_demographics.cd_demo_sk
JOIN household_demographics ON web_sales.ws_bill_hdemo_sk = household_demographics.hd_demo_sk
JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
WHERE date_dim.d_year BETWEEN 2000 AND 2002
GROUP BY date_dim.d_year,
         customer_demographics.cd_gender,
         income_band.ib_lower_bound,
         income_band.ib_upper_bound

ORDER BY d_year, channel, cd_gender, ib_lower_bound
