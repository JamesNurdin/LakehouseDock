WITH sales_2001 AS (
    SELECT
        cs.cs_order_number AS order_number,
        d.d_year AS year,
        cs.cs_net_paid AS net_paid,
        cc.cc_name AS call_center_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
)
SELECT
    order_number,
    year,
    net_paid,
    call_center_name
FROM sales_2001
EXCEPT
SELECT
    cr.cr_order_number AS order_number,
    d.d_year AS year,
    cr.cr_return_amount AS net_paid,
    cc.cc_name AS call_center_name
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE d.d_year = 2001
  AND cc.cc_state = 'CA'
