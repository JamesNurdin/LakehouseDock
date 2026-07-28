WITH demo_income AS (
   SELECT hd.hd_demo_sk,
          ib.ib_lower_bound,
          ib.ib_upper_bound
   FROM household_demographics hd
   JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT *
FROM (
   SELECT d.d_year AS year,
          concat('Income_', cast(di.ib_lower_bound AS varchar), '-', cast(di.ib_upper_bound AS varchar)) AS segment,
          'Sales' AS metric,
          SUM(cs.cs_net_paid) AS total_amount,
          COUNT(*) AS total_cnt
   FROM catalog_sales cs
   JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN demo_income di
        ON cs.cs_bill_hdemo_sk = di.hd_demo_sk
   WHERE regexp_like(cp.cp_description, '(?i)toy|gadget')
   GROUP BY d.d_year, di.ib_lower_bound, di.ib_upper_bound
   UNION ALL
   SELECT d.d_year AS year,
          s.s_city AS segment,
          'Returns' AS metric,
          SUM(sr.sr_return_amt) AS total_amount,
          COUNT(*) AS total_cnt
   FROM store_returns sr
   JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
   JOIN demo_income di
        ON sr.sr_hdemo_sk = di.hd_demo_sk
   WHERE s.s_city LIKE '%York%'
     AND regexp_like(s.s_street_name, '^[0-9]{1,2}[A-Za-z]?')
   GROUP BY d.d_year, s.s_city
) combined
ORDER BY year DESC, segment
