WITH joined_data AS (
    SELECT
        d.d_year AS d_year,
        cd.cd_gender AS cd_gender,
        p.p_channel_dmail AS p_channel_dmail,
        c.c_customer_id AS c_customer_id,
        cr.cr_return_amount AS cr_return_amount,
        cr.cr_return_quantity AS cr_return_quantity,
        cr.cr_fee AS cr_fee,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_quantity AS ws_quantity
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND p.p_channel_dmail = 'Y'
      AND cd.cd_gender = 'M'
      AND c.c_preferred_cust_flag = 'Y'
      AND cr.cr_return_quantity > 1
      AND wp.wp_type = 'home'
)
SELECT
    d_year,
    cd_gender,
    p_channel_dmail,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ws_ext_sales_price) AS total_sales_amount,
    AVG(ws_quantity) AS avg_sales_quantity,
    MIN(cr_fee) AS min_return_fee,
    MAX(cr_fee) AS max_return_fee
FROM joined_data
GROUP BY d_year, cd_gender, p_channel_dmail
HAVING SUM(cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
