WITH base AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_ext_sales_price,
    ss.ss_quantity,
    ss.ss_net_paid,
    ss.ss_store_sk,
    ss.ss_customer_sk,
    ss.ss_promo_sk,
    ss.ss_hdemo_sk,
    ss.ss_cdemo_sk,
    ss.ss_addr_sk,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_purchase_estimate,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_promo_name,
    p.p_channel_demo,
    s.s_store_name,
    s.s_suite_number,
    wp.wp_url
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
  WHERE p.p_channel_demo = 'N'
    AND s.s_suite_number LIKE 'Suite %'
    AND hd.hd_vehicle_count >= 0
    AND cd.cd_purchase_estimate > 5000
),
agg1 AS (
  SELECT
    c_customer_id,
    s_store_name,
    hd_vehicle_count,
    ss_promo_sk,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    SUM(DISTINCT ss_ext_sales_price) AS sum_distinct_sales,
    AVG(ss_quantity) AS avg_quantity,
    CASE
      WHEN hd_vehicle_count >= 2 THEN 'HighVehicle'
      ELSE 'LowVehicle'
    END AS vehicle_category,
    (
      SELECT MAX(p2.p_cost)
      FROM promotion p2
      WHERE p2.p_promo_sk = ss_promo_sk
    ) AS max_promo_cost
  FROM base
  GROUP BY c_customer_id, s_store_name, hd_vehicle_count, ss_promo_sk
),
intersect_set AS (
  SELECT ss_ticket_number FROM store_sales WHERE ss_ext_sales_price > 5000
  INTERSECT
  SELECT ss_ticket_number FROM store_sales WHERE ss_quantity >= 5
)
SELECT
  a.c_customer_id,
  a.s_store_name,
  a.distinct_tickets,
  a.sum_distinct_sales,
  a.avg_quantity,
  a.vehicle_category,
  a.max_promo_cost,
  ic.cnt_intersect
FROM agg1 a
LEFT JOIN (
  SELECT COUNT(*) AS cnt_intersect FROM intersect_set
) ic ON TRUE
WHERE a.sum_distinct_sales > 10000
ORDER BY a.sum_distinct_sales DESC, a.c_customer_id
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
