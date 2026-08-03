/*
Goal: Rank items per California store by net profit for 2020, filter high‑value sales, and keep only stores that have no matching call center in the same city (anti‑join).
*/
WITH sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    WHERE ss.ss_ext_sales_price > 1000
      AND ss.ss_quantity >= 2
    GROUP BY
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk
)
SELECT
    s.s_store_name,
    i.i_product_name,
    d_sales.d_date               AS sale_date,
    t.t_hour                     AS sale_hour,
    c.c_first_name,
    cd.cd_gender,
    ws.web_name,
    sa.total_sales,
    sa.total_profit,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY sa.total_profit DESC) AS profit_rank,
    (
        SELECT AVG(total_profit)
        FROM sales_agg sa2
        WHERE sa2.ss_store_sk = sa.ss_store_sk
    ) AS avg_store_profit
FROM sales_agg sa
JOIN date_dim d_sales       ON sa.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t             ON sa.ss_sold_time_sk = t.t_time_sk
JOIN store s                ON sa.ss_store_sk = s.s_store_sk
JOIN item i                 ON sa.ss_item_sk = i.i_item_sk
JOIN customer c             ON sa.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON sa.ss_cdemo_sk = cd.cd_demo_sk
JOIN web_site ws            ON ws.web_open_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year = 2020
  AND i.i_brand = 'Brand#12'
  AND s.s_state = 'CA'
  AND cd.cd_gender = 'M'
  AND NOT EXISTS (
        SELECT 1
        FROM call_center cc
        WHERE cc.cc_city = s.s_city
          AND cc.cc_state = s.s_state
          AND cc.cc_closed_date_sk = d_sales.d_date_sk
    )
ORDER BY s.s_store_name, profit_rank
LIMIT 100
