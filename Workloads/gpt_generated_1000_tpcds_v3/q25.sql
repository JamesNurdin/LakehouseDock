WITH joined_data AS (
    SELECT
        cc.cc_name,
        c.c_customer_id,
        ca.ca_state,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_sales_price,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        r.r_reason_desc,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_sales_price,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        r2.r_reason_desc AS wr_reason_desc,
        wsite.web_name
    FROM
        catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r2
        ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE
        c.c_birth_year BETWEEN 1945 AND 1970
        AND ca.ca_state IN ('CA', 'TX', 'NY')
        AND r.r_reason_desc LIKE '%damaged%'
        AND ws.ws_sales_price > 100
        AND wr.wr_return_amt > 50
)
SELECT
    cc_name,
    c_customer_id,
    ca_state,
    COUNT(DISTINCT cs_order_number) AS num_catalog_orders,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(cr_return_amount) AS total_catalog_returns,
    COUNT(DISTINCT ws_order_number) AS num_web_orders,
    SUM(ws_ext_sales_price) AS total_web_sales,
    SUM(wr_return_amt) AS total_web_returns,
    AVG(cs_quantity) AS avg_catalog_quantity,
    AVG(ws_quantity) AS avg_web_quantity,
    MIN(cs_sales_price) AS min_catalog_price,
    MAX(ws_sales_price) AS max_web_price
FROM
    joined_data
GROUP BY
    cc_name,
    c_customer_id,
    ca_state
HAVING
    SUM(cs_ext_sales_price) > 1000
    AND SUM(ws_ext_sales_price) > 500
    AND COUNT(DISTINCT cs_order_number) >= 5
ORDER BY
    total_catalog_sales DESC
LIMIT 100
