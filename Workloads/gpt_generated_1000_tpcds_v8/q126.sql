/*
Goal: Compare high‑profit store sales in 2021 for customers from high‑income households with low‑profit sales in 2022, returning a unified list that includes the household income band upper bound and a global row number.
*/
WITH sales_2021 AS (
    SELECT
        ss.ss_ticket_number,
        d.d_year,
        i.i_item_id,
        i.i_product_name,
        s.s_store_name,
        ss.ss_net_profit,
        (
            SELECT ib.ib_upper_bound
            FROM income_band ib
            JOIN household_demographics hd ON hd.hd_income_band_sk = ib.ib_income_band_sk
            WHERE hd.hd_demo_sk = ss.ss_hdemo_sk
        ) AS income_upper_bound
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2021
      AND ss.ss_net_profit > 5000
      AND (
            SELECT ib.ib_upper_bound
            FROM income_band ib
            JOIN household_demographics hd ON hd.hd_income_band_sk = ib.ib_income_band_sk
            WHERE hd.hd_demo_sk = ss.ss_hdemo_sk
          ) > 150000
),
sales_2022 AS (
    SELECT
        ss.ss_ticket_number,
        d.d_year,
        i.i_item_id,
        i.i_product_name,
        s.s_store_name,
        ss.ss_net_profit,
        (
            SELECT ib.ib_upper_bound
            FROM income_band ib
            JOIN household_demographics hd ON hd.hd_income_band_sk = ib.ib_income_band_sk
            WHERE hd.hd_demo_sk = ss.ss_hdemo_sk
        ) AS income_upper_bound
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2022
      AND ss.ss_net_profit BETWEEN 0 AND 1000
)
SELECT
    ticket_number,
    year,
    item_id,
    product_name,
    store_name,
    net_profit,
    income_upper_bound,
    ROW_NUMBER() OVER (ORDER BY net_profit DESC) AS row_num
FROM (
    SELECT
        ss_ticket_number AS ticket_number,
        d_year         AS year,
        i_item_id      AS item_id,
        i_product_name AS product_name,
        s_store_name   AS store_name,
        ss_net_profit  AS net_profit,
        income_upper_bound
    FROM sales_2021
    UNION ALL
    SELECT
        ss_ticket_number AS ticket_number,
        d_year         AS year,
        i_item_id      AS item_id,
        i_product_name AS product_name,
        s_store_name   AS store_name,
        ss_net_profit  AS net_profit,
        income_upper_bound
    FROM sales_2022
) u
LIMIT 100
