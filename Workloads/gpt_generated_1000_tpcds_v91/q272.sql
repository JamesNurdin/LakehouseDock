WITH joined_returns AS (
  SELECT
    cr.cr_order_number AS order_number,
    d_ret.d_date AS return_date,
    d_ret.d_year AS return_year,
    t.t_hour AS return_hour,
    i.i_item_id,
    i.i_product_name,
    i.i_item_desc,
    regexp_extract(i.i_item_desc, '([A-Za-z]+)', 1) AS extracted_word,
    sm.sm_carrier,
    c.c_customer_id,
    c.c_birth_country,
    cp.cp_type,
    concat(c.c_customer_id, '-', cp.cp_type) AS cust_page_concat,
    substr(i.i_product_name, 1, 10) AS product_name_prefix,
    CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_indicator,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d_ret.d_date DESC) AS rn,
    ws.web_name
  FROM catalog_returns cr
  JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
)
SELECT
  order_number,
  return_date,
  return_hour,
  i_item_id,
  i_product_name,
  extracted_word,
  sm_carrier,
  c_customer_id,
  c_birth_country,
  cp_type,
  cust_page_concat,
  product_name_prefix,
  loss_indicator,
  rn,
  web_name
FROM joined_returns
WHERE
  regexp_like(i_item_desc, '^[A-Z]{2,}[0-9]{3,}$')
  AND sm_carrier LIKE 'FE%'
  AND c_birth_country = 'KOREA'
  AND return_year = 1999

EXCEPT

SELECT
  order_number,
  return_date,
  return_hour,
  i_item_id,
  i_product_name,
  extracted_word,
  sm_carrier,
  c_customer_id,
  c_birth_country,
  cp_type,
  cust_page_concat,
  product_name_prefix,
  loss_indicator,
  rn,
  web_name
FROM joined_returns
WHERE
  regexp_like(i_item_desc, 'Gold')
  AND sm_carrier NOT LIKE 'FE%'
  AND c_birth_country <> 'KOREA'
  AND return_year = 1999

ORDER BY return_date DESC, loss_indicator
LIMIT 100
