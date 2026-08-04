WITH
  base AS (
    SELECT
      ss.ss_promo_sk,
      ss.ss_hdemo_sk,
      ss.ss_coupon_amt,
      ss.ss_net_paid,
      hd.hd_vehicle_count,
      p.p_channel_tv,
      p.p_discount_active,
      ld.max_discount
    FROM tpcds.store_sales ss
    FULL OUTER JOIN tpcds.promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN tpcds.household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN LATERAL (
      SELECT MAX(s2.ss_ext_discount_amt) AS max_discount
      FROM tpcds.store_sales s2
      WHERE s2.ss_promo_sk = ss.ss_promo_sk
    ) ld
    WHERE
      ss.ss_coupon_amt > 100
      AND hd.hd_vehicle_count >= 1
      AND p.p_channel_tv = 'N'
      AND p.p_discount_active = 'Y'
  ),
  aggregated AS (
    SELECT
      ss_hdemo_sk,
      SUM(ss_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
    FROM base
    GROUP BY ss_hdemo_sk
  ),
  demo_stats AS (
    SELECT
      hd.hd_demo_sk,
      hd.hd_vehicle_count,
      agg.total_net_paid,
      agg.sales_cnt,
      CASE WHEN hd.hd_vehicle_count = 0 THEN NULL
           ELSE agg.total_net_paid / hd.hd_vehicle_count
      END AS net_per_vehicle
    FROM aggregated agg
    JOIN tpcds.household_demographics hd
      ON agg.ss_hdemo_sk = hd.hd_demo_sk
  )
SELECT
  d.hd_vehicle_count,
  AVG(d.net_per_vehicle) AS avg_net_per_vehicle,
  SUM(d.sales_cnt) AS total_sales_cnt
FROM demo_stats d
WHERE d.total_net_paid > (SELECT AVG(ss_net_paid) FROM tpcds.store_sales)
GROUP BY d.hd_vehicle_count
HAVING COUNT(*) >= 5

UNION DISTINCT

SELECT
  d.hd_vehicle_count,
  AVG(d.net_per_vehicle) AS avg_net_per_vehicle,
  SUM(d.sales_cnt) AS total_sales_cnt
FROM demo_stats d
WHERE d.total_net_paid <= (SELECT AVG(ss_net_paid) FROM tpcds.store_sales)
GROUP BY d.hd_vehicle_count
HAVING COUNT(*) >= 1

ORDER BY avg_net_per_vehicle DESC
LIMIT 100
