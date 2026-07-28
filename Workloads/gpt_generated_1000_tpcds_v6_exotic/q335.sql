WITH joined_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        hd.hd_income_band_sk,
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_coupon_amt,
        ws.ws_net_profit,
        ws.ws_quantity,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        wp.wp_type,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        i.i_current_price BETWEEN 50 AND 150
        AND c.c_birth_year BETWEEN 1950 AND 1970
        AND ca.ca_state IN ('CA', 'TX', 'NY')
        AND cd.cd_gender = 'M'
        AND cs.cs_coupon_amt > 500
        AND ws.ws_quantity >= 2
        AND wp.wp_type = 'Content'
)
SELECT
    jd.c_customer_sk,
    jd.c_first_name,
    jd.c_last_name,
    jd.i_category,
    SUM(jd.cs_net_profit) AS total_catalog_profit,
    SUM(jd.ws_net_profit) AS total_web_profit,
    SUM(jd.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT jd.cs_order_number) AS orders_count
FROM joined_data jd
GROUP BY
    jd.c_customer_sk,
    jd.c_first_name,
    jd.c_last_name,
    jd.i_category
HAVING
    SUM(jd.cs_net_profit) > (
        SELECT AVG(cat_profit)
        FROM (
            SELECT i.i_category,
                   SUM(cs.cs_net_profit) AS cat_profit
            FROM catalog_sales cs
            JOIN item i
                ON cs.cs_item_sk = i.i_item_sk
            GROUP BY i.i_category
        ) AS cat_totals
    )
ORDER BY total_catalog_profit DESC
LIMIT 100
