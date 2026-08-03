WITH
  /* Customers that bought using promotions whose name contains the word 'Discount' on US‑based web sites */
  customer_web AS (
    SELECT DISTINCT c.c_customer_sk AS cust_sk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE regexp_like(p.p_promo_name, 'Discount')
      AND w.web_name LIKE '%US%'
  ),

  /* Customers that returned items to stores whose name starts with "A" located in cities beginning with "San" */
  customer_store AS (
    SELECT DISTINCT c.c_customer_sk AS cust_sk
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE regexp_like(s.s_store_name, '^A.*')
      AND s.s_city LIKE 'San%'
  ),

  /* Customers appearing in both previous sets */
  common_customers AS (
    SELECT cust_sk FROM customer_web
    INTERSECT
    SELECT cust_sk FROM customer_store
  ),

  /* Store information together with its closed date */
  store_dates AS (
    SELECT s.s_store_sk,
           s.s_store_name,
           s.s_city,
           d.d_date AS closed_date
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
  ),

  /* Call‑center information together with its closed date */
  call_center_dates AS (
    SELECT cc.cc_call_center_sk,
           cc.cc_name,
           cc.cc_city,
           d.d_date AS closed_date
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
  ),

  /* Full outer join stores and call‑centers on the *exact* closed date */
  store_cc_full AS (
    SELECT
      COALESCE(sd.s_store_sk, 0)               AS store_sk,
      sd.s_store_name,
      sd.s_city                               AS store_city,
      COALESCE(cd.cc_call_center_sk, 0)       AS call_center_sk,
      cd.cc_name                              AS call_center_name,
      cd.cc_city                              AS call_center_city,
      COALESCE(sd.closed_date, cd.closed_date) AS closed_date
    FROM store_dates sd
    FULL OUTER JOIN call_center_dates cd
      ON sd.closed_date = cd.closed_date
  ),

  /* Rank each record per closed date, keep only stores that have at least one common customer return */
  ranked_results AS (
    SELECT
      scf.store_sk,
      scf.s_store_name,
      scf.call_center_name,
      scf.closed_date,
      ROW_NUMBER() OVER (PARTITION BY scf.closed_date
                         ORDER BY scf.s_store_name NULLS LAST) AS rank_per_date
    FROM store_cc_full scf
    WHERE (
      scf.store_sk <> 0 AND EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN common_customers cc ON sr.sr_customer_sk = cc.cust_sk
        WHERE sr.sr_store_sk = scf.store_sk
      )
    )
       OR scf.call_center_sk <> 0
  )

SELECT
  rr.store_sk,
  rr.s_store_name,
  rr.call_center_name,
  rr.closed_date,
  rr.rank_per_date,
  CASE
    WHEN rr.s_store_name IS NOT NULL THEN concat('Store:', substr(rr.s_store_name, 1, 10))
    ELSE concat('CallCenter:', substr(rr.call_center_name, 1, 10))
  END AS label
FROM ranked_results rr
WHERE rr.rank_per_date <= 5
ORDER BY rr.closed_date DESC, rr.rank_per_date
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
