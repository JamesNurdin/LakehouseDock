WITH base AS (
  SELECT
    ss.ss_store_sk AS store_sk,
    d1.d_year,
    cd.cd_gender,
    hd.hd_buy_potential,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY d1.d_year ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
  FROM store_sales ss
  JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
  JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN catalog_returns cr ON cr.cr_returned_date_sk = d1.d_date_sk
  JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON wp.wp_creation_date_sk = d1.d_date_sk
  JOIN web_site ws ON ws.web_open_date_sk = d1.d_date_sk
  WHERE d1.d_year BETWEEN 2000 AND 2002                -- predicate 1
    AND d1.d_moy IN (1, 2, 3)                         -- predicate 2
    AND cd.cd_credit_rating = 'Good      '          -- predicate 3
    AND hd.hd_buy_potential = '>10000         '    -- predicate 4
    AND cc.cc_country = 'United States'             -- predicate 5
    AND cp.cp_type = 'promo'                         -- predicate 6
    AND ws.web_name = 'Internet'                     -- predicate 7
  GROUP BY ss.ss_store_sk, d1.d_year, cd.cd_gender, hd.hd_buy_potential
),
high_sales AS (
  SELECT store_sk, d_year, total_net_paid
  FROM base
  WHERE total_net_paid > 1000000
),
high_returns AS (
  SELECT store_sk, d_year, total_return_amount
  FROM base
  WHERE total_return_amount > 500000
)
SELECT hs.store_sk,
       hs.d_year,
       hs.total_net_paid
FROM high_sales hs
EXCEPT
SELECT hr.store_sk,
       hr.d_year,
       hr.total_return_amount
FROM high_returns hr
ORDER BY d_year,
         total_net_paid DESC
LIMIT 100
