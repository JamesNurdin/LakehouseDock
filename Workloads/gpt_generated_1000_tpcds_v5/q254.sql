WITH distinct_cc AS (
        SELECT DISTINCT
            cc.cc_call_center_sk,
            cc.cc_name,
            cc.cc_tax_percentage
        FROM call_center cc
        WHERE cc.cc_tax_percentage < 0.05
    ),
    filtered_sales AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_customer_sk,
            ss.ss_cdemo_sk,
            ss.ss_ext_sales_price,
            ss.ss_ext_tax,
            ss.ss_net_profit,
            ss.ss_quantity
        FROM store_sales ss
        WHERE ss.ss_ext_sales_price > 1000
          AND ss.ss_ext_tax BETWEEN 10 AND 300
          AND ss.ss_quantity >= 1
          AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2455000
    )
SELECT
    c.c_customer_id,
    cd.cd_gender,
    dcc.cc_name,
    cp.cp_department,
    COALESCE(w.w_state, 'UNKNOWN') AS warehouse_state,
    fss.ss_ext_sales_price,
    fss.ss_ext_tax,
    fss.ss_net_profit,
    cr.cr_return_amount,
    cr.cr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY fss.ss_ext_sales_price DESC) AS rn
FROM filtered_sales fss
JOIN customer c
    ON fss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON fss.ss_cdemo_sk = cd.cd_demo_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN distinct_cc dcc
    ON cr.cr_call_center_sk = dcc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE c.c_birth_country = 'United States'
  AND cd.cd_credit_rating = 'GOOD'
  AND cp.cp_type = 'PROMO'
  AND w.w_gmt_offset IS NOT NULL
  AND EXISTS (
        SELECT 1
        FROM customer_demographics cd2
        WHERE cd2.cd_gender = cd.cd_gender
          AND cd2.cd_marital_status = 'M'
      )
ORDER BY rn
LIMIT 100
