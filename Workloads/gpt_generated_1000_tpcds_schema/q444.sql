WITH
  cr_agg AS (
    SELECT
      cr.cr_call_center_sk,
      cr.cr_returned_date_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100
    GROUP BY cr.cr_call_center_sk, cr.cr_returned_date_sk
  ),
  cust_demo AS (
    SELECT
      c.c_customer_sk,
      c.c_salutation,
      hd.hd_buy_potential,
      hd.hd_income_band_sk,
      hd.hd_dep_count
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential = '1001-5000'
  ),
  set_a AS (
    SELECT c_customer_sk
    FROM cust_demo
    WHERE hd_income_band_sk >= 15
  ),
  set_b AS (
    SELECT cr.cr_refunded_customer_sk AS c_customer_sk
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first'
  ),
  intersect_set AS (
    SELECT c_customer_sk FROM set_a
    INTERSECT
    SELECT c_customer_sk FROM set_b
  ),
  union_set AS (
    SELECT c_customer_sk FROM intersect_set
    UNION
    SELECT c_customer_sk FROM set_a
  ),
  final AS (
    SELECT
      cc.cc_name,
      cd.total_return_amount,
      cd.return_cnt,
      CASE WHEN cd.total_return_amount > 5000 THEN 'HIGH' ELSE 'LOW' END AS return_category,
      wp.wp_max_ad_count,
      hd.hd_buy_potential,
      LAG(cd.total_return_amount) OVER (PARTITION BY cc.cc_name ORDER BY cd.cr_returned_date_sk) AS prev_total_return,
      ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY cd.total_return_amount DESC) AS rn
    FROM cr_agg cd
    JOIN call_center cc ON cd.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
                           AND cr.cr_returned_date_sk = cd.cr_returned_date_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wp.wp_max_ad_count >= 1
      AND td.t_hour BETWEEN 8 AND 18
      AND cc.cc_state = 'CA'
      AND c.c_salutation = 'Mr.'
      AND hd.hd_dep_count <= 4
      AND c.c_customer_sk IN (SELECT c_customer_sk FROM union_set)
  )
SELECT
  cc_name,
  total_return_amount,
  return_cnt,
  return_category,
  wp_max_ad_count,
  hd_buy_potential,
  prev_total_return,
  rn
FROM final
WHERE rn <= 10
ORDER BY total_return_amount DESC
OFFSET 5 ROWS FETCH NEXT 100 ROWS ONLY
