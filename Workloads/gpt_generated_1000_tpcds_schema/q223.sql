WITH
  catalog_ret AS (
    SELECT
      c.c_email_address,
      cr.cr_return_amount,
      cr.cr_returned_date_sk,
      r.r_reason_desc,
      ARRAY[cr.cr_return_quantity, CAST(cr.cr_return_amount AS DOUBLE)] AS qty_amount_arr
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 100
      AND EXISTS (
        SELECT 1
        FROM household_demographics hd
        WHERE hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
          AND hd.hd_income_band_sk = 5
      )
  ),
  catalog_ret_unnest AS (
    SELECT
      c_email_address,
      cr_return_amount,
      cr_returned_date_sk,
      r_reason_desc,
      qty_elem
    FROM catalog_ret
    CROSS JOIN UNNEST(qty_amount_arr) AS t (qty_elem)
  ),
  web_sales_sel AS (
    SELECT
      c.c_email_address,
      ws.ws_net_paid,
      ws.ws_sold_date_sk,
      ws.ws_ext_ship_cost,
      ARRAY[ws.ws_quantity, ws.ws_ext_ship_cost] AS qty_ship_arr
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_ext_ship_cost > 1000
      AND EXISTS (
        SELECT 1
        FROM customer_demographics cd
        WHERE cd.cd_demo_sk = ws.ws_bill_cdemo_sk
          AND cd.cd_education_status = 'College'
      )
  ),
  web_sales_unnest AS (
    SELECT
      c_email_address,
      ws_net_paid,
      ws_sold_date_sk,
      ws_ext_ship_cost,
      qty_elem
    FROM web_sales_sel
    CROSS JOIN UNNEST(qty_ship_arr) AS t (qty_elem)
  )
SELECT
  email,
  amount,
  date_key,
  category,
  element
FROM (
  SELECT
    c_email_address AS email,
    cr_return_amount AS amount,
    cr_returned_date_sk AS date_key,
    r_reason_desc AS category,
    qty_elem AS element
  FROM catalog_ret_unnest
  UNION ALL
  SELECT
    c_email_address AS email,
    ws_net_paid AS amount,
    ws_sold_date_sk AS date_key,
    'Web Sale' AS category,
    qty_elem AS element
  FROM web_sales_unnest
) AS combined
ORDER BY amount DESC
LIMIT 100
