WITH sales_keys AS (
   SELECT cs_order_number
   FROM tpcds.catalog_sales
   TABLESAMPLE BERNOULLI (10)    -- sample 10% of catalog_sales rows
   WHERE cs_sold_date_sk BETWEEN 2450815 AND 2451200
),
returns_keys AS (
   SELECT cr_order_number
   FROM tpcds.catalog_returns
   WHERE cr_returned_date_sk BETWEEN 2450815 AND 2451200
),
order_numbers AS (
   SELECT cs_order_number
   FROM sales_keys
   EXCEPT
   SELECT cr_order_number
   FROM returns_keys
),
base AS (
   SELECT
       cs.cs_net_profit,
       cs.cs_sold_date_sk,
       cs.cs_order_number,
       cs.cs_catalog_page_sk,
       cp.cp_department,
       cp.cp_type,
       c.c_customer_id,
       c.c_customer_sk,
       d.d_year,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       ss.ss_ext_list_price,
       s.s_state
   FROM order_numbers onr
   JOIN tpcds.catalog_sales cs
       ON cs.cs_order_number = onr.cs_order_number
   JOIN tpcds.catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN tpcds.catalog_returns cr
       ON cr.cr_order_number = cs.cs_order_number
   JOIN tpcds.customer c
       ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN tpcds.date_dim d
       ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN tpcds.household_demographics hd
       ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN tpcds.store_sales ss
       ON ss.ss_customer_sk = c.c_customer_sk
   JOIN tpcds.store s
       ON ss.ss_store_sk = s.s_store_sk
   WHERE cp.cp_type = 'A'                           -- filter 1
     AND ib.ib_upper_bound > 50000                 -- filter 2
     AND s.s_state = 'CA'                          -- filter 3
     AND ss.ss_ext_list_price > 1000               -- filter 4
     AND NOT EXISTS (
         SELECT 1
         FROM tpcds.store_sales ss2
         WHERE ss2.ss_customer_sk = c.c_customer_sk
           AND ss2.ss_sold_date_sk = cs.cs_sold_date_sk
     )                                             -- anti‑join filter
)
SELECT
    c_customer_id,
    d_year,
    cp_department,
    total_profit,
    CASE WHEN total_profit > 10000 THEN 'High' ELSE 'Medium' END AS profit_level,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_profit DESC) AS dept_rank
FROM (
    SELECT
        c_customer_id,
        d_year,
        cp_department,
        SUM(cs_net_profit) AS total_profit
    FROM base
    GROUP BY c_customer_id, d_year, cp_department
) agg
ORDER BY dept_rank, total_profit DESC
LIMIT 100
