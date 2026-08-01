WITH returns_agg AS (
   SELECT
       s.s_store_name AS store_name,
       d.d_year AS year,
       cd.cd_gender AS cd_gender,
       ib.ib_lower_bound AS ib_lower_bound,
       SUM(sr.sr_return_amt) AS total_amount,
       'return' AS metric_type
   FROM store_returns sr
   JOIN date_dim d
       ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN time_dim t
       ON sr.sr_return_time_sk = t.t_time_sk
   JOIN customer c
       ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
       ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
       ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN store s
       ON sr.sr_store_sk = s.s_store_sk
   JOIN promotion p
       ON d.d_date_sk = p.p_start_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND cd.cd_gender = 'M'
     AND cd.cd_marital_status = 'M'
     AND hd.hd_vehicle_count > 1
     AND ib.ib_lower_bound >= 50000
     AND s.s_state = 'CA'
     AND p.p_discount_active = 'Y'
     AND NOT EXISTS (
         SELECT 1 FROM promotion p2
         WHERE p2.p_end_date_sk = d.d_date_sk
           AND p2.p_promo_sk = p.p_promo_sk
     )
   GROUP BY
       s.s_store_name,
       d.d_year,
       cd.cd_gender,
       ib.ib_lower_bound
),

inventory_agg AS (
   SELECT
       s.s_store_name AS store_name,
       d.d_year AS year,
       CAST(NULL AS varchar) AS cd_gender,
       CAST(NULL AS integer) AS ib_lower_bound,
       SUM(i.inv_quantity_on_hand) AS total_amount,
       'inventory' AS metric_type
   FROM inventory i
   JOIN date_dim d
       ON i.inv_date_sk = d.d_date_sk
   JOIN store s
       ON s.s_closed_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND s.s_state = 'CA'
   GROUP BY
       s.s_store_name,
       d.d_year
),

combined AS (
   SELECT * FROM returns_agg
   UNION ALL
   SELECT * FROM inventory_agg
)
SELECT
    store_name,
    year,
    metric_type,
    SUM(total_amount) AS metric_total,
    RANK() OVER (PARTITION BY metric_type ORDER BY SUM(total_amount) DESC) AS metric_rank
FROM combined
GROUP BY GROUPING SETS (
    (store_name, year, metric_type),
    (store_name, metric_type),
    (year, metric_type),
    (metric_type),
    ()
)
ORDER BY metric_type, metric_total DESC
LIMIT 100
