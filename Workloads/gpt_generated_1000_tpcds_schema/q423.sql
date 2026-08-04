WITH sales_filtered AS (
  SELECT
    cs.cs_call_center_sk,
    cs.cs_ext_sales_price,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_profit,
    cc.cc_call_center_sk AS dim_cc_call_center_sk,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    cc.cc_zip,
    cc.cc_street_name,
    cc.cc_street_number
  FROM catalog_sales cs
  RIGHT OUTER JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE regexp_like(cc.cc_name, '(?i)center')
    AND cc.cc_city LIKE '%York%'
),
extracted AS (
  SELECT
    sf.*, 
    regexp_extract(sf.cc_street_name, '([A-Za-z]+)', 1) AS street_word,
    substring(sf.cc_zip, 1, 5) AS zip_prefix,
    concat(sf.cc_city, '-', sf.cc_state) AS city_state
  FROM sales_filtered sf
),
lateral_calc AS (
  SELECT
    e.*, 
    nl.name_len
  FROM extracted e
  CROSS JOIN LATERAL (
    SELECT length(e.cc_name) AS name_len
  ) nl
),
sales_keys AS (
  SELECT DISTINCT dim_cc_call_center_sk FROM lateral_calc
),
exclude_keys AS (
  SELECT cc_call_center_sk FROM call_center WHERE cc_state = 'CA'
),
final_keys AS (
  SELECT dim_cc_call_center_sk FROM sales_keys
  EXCEPT
  SELECT cc_call_center_sk FROM exclude_keys
)
SELECT
  lc.cc_state,
  lc.cc_city,
  SUM(lc.cs_ext_sales_price) AS total_sales,
  COUNT(lc.cs_order_number) AS order_cnt,
  SUM(lc.cs_net_profit) AS total_profit
FROM lateral_calc lc
WHERE lc.dim_cc_call_center_sk IN (SELECT dim_cc_call_center_sk FROM final_keys)
GROUP BY ROLLUP (lc.cc_state, lc.cc_city)
ORDER BY total_sales DESC
LIMIT 100
