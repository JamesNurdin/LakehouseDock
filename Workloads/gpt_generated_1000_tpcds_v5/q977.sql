WITH filtered_cust AS (
   SELECT cd_demo_sk,
          cd_gender,
          cd_credit_rating
   FROM customer_demographics
   WHERE cd_gender = 'M'
     AND regexp_like(cd_credit_rating, '^A[0-9]{2}$')
),
filtered_hh AS (
   SELECT hd_demo_sk,
          hd_buy_potential,
          regexp_extract(hd_buy_potential, '([0-9]+)-([0-9]+)', 1) AS lower_bound,
          regexp_extract(hd_buy_potential, '([0-9]+)-([0-9]+)', 2) AS upper_bound
   FROM household_demographics
   WHERE hd_buy_potential LIKE '%-%'
     AND regexp_like(hd_buy_potential, '^[0-9]+-[0-9]+$')
),
sales_agg AS (
   SELECT w.w_warehouse_name AS warehouse_name,
          d.d_year,
          hh.lower_bound,
          hh.upper_bound,
          sum(cs.cs_net_profit) AS total_profit,
          count(*) AS order_cnt,
          avg(cs.cs_ext_tax) AS avg_tax,
          concat('Potential ', hh.hd_buy_potential) AS buy_potential_desc
   FROM catalog_sales cs
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN filtered_cust c
     ON cs.cs_bill_cdemo_sk = c.cd_demo_sk
   JOIN filtered_hh hh
     ON cs.cs_bill_hdemo_sk = hh.hd_demo_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY w.w_warehouse_name,
            d.d_year,
            hh.lower_bound,
            hh.upper_bound,
            hh.hd_buy_potential
)
SELECT warehouse_name,
       d_year,
       lower_bound,
       upper_bound,
       total_profit,
       order_cnt,
       avg_tax,
       buy_potential_desc
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
