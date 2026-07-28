WITH sales_agg AS (
    SELECT
        cp.cp_department,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS total_orders,
        CASE WHEN SUM(cs.cs_net_profit) >= 50000 THEN 'HIGH' ELSE 'LOW' END AS profit_class,
        MIN(REGEXP_EXTRACT(cp.cp_description, '([A-Za-z]+)', 1)) AS sample_desc_word,
        MIN(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS sample_customer_name
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN promotion p              ON cs.cs_promo_sk       = p.p_promo_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND REGEXP_LIKE(cp.cp_description, '(?i)season')
      AND c.c_email_address LIKE '%@example.com'
      AND cd.cd_credit_rating = 'Good'
      AND hd.hd_buy_potential = '>10000'
    GROUP BY cp.cp_department, d.d_year, d.d_month_seq
    HAVING SUM(cs.cs_net_profit) > 1000
)
SELECT
    s.cp_department,
    s.d_year,
    s.d_month_seq,
    s.total_profit,
    s.total_orders,
    s.profit_class,
    s.sample_desc_word,
    s.sample_customer_name,
    RANK() OVER (PARTITION BY s.cp_department ORDER BY s.total_profit DESC) AS profit_rank,
    SUM(s.total_profit) OVER (PARTITION BY s.cp_department) AS dept_total_profit
FROM sales_agg s
ORDER BY s.total_profit DESC
LIMIT 100
