WITH returns_data AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        cr.cr_return_amount AS amount,
        sm.sm_ship_mode_id,
        cd.cd_education_status
    FROM catalog_returns cr
    RIGHT OUTER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount > 0
      AND EXISTS (
          SELECT 1
          FROM customer_address ca
          WHERE ca.ca_state = 'CA'
            AND ca.ca_address_sk = cr.cr_returning_addr_sk
      )
),
sales_data AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_ext_sales_price AS amount,
        sm.sm_ship_mode_id,
        cd.cd_education_status
    FROM web_sales ws
    FULL OUTER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_ext_sales_price > 0
      AND w.web_country = 'United States'
),
college_returns AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        cr.cr_return_amount AS amount,
        sm.sm_ship_mode_id,
        cd.cd_education_status
    FROM catalog_returns cr
    INNER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'College'
)
SELECT
    combined.customer_sk,
    combined.amount,
    combined.sm_ship_mode_id,
    combined.cd_education_status
FROM (
    SELECT customer_sk, amount, sm_ship_mode_id, cd_education_status FROM returns_data
    UNION
    SELECT customer_sk, amount, sm_ship_mode_id, cd_education_status FROM sales_data
) AS combined
EXCEPT
SELECT customer_sk, amount, sm_ship_mode_id, cd_education_status FROM college_returns
ORDER BY amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
