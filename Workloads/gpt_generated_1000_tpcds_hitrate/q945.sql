WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        ca.ca_country,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_store_return,
        SUM(wr.wr_return_amt) AS total_web_return,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        CASE WHEN SUM(cs.cs_quantity) > 5 THEN 'Bulk' ELSE 'Single' END AS purchase_type
    FROM
        catalog_sales cs TABLESAMPLE BERNOULLI (10)
        JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN store_returns sr
            ON sr.sr_customer_sk = c.c_customer_sk
        JOIN web_sales ws
            ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_returns wr
            ON wr.wr_item_sk = ws.ws_item_sk
    WHERE
        ca.ca_country = 'United States'
        AND cd.cd_gender = 'M'
        AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451195
        AND sr.sr_store_credit > 10
        AND wp.wp_type = 'content'
        AND wr.wr_fee < 50
        AND cs.cs_order_number NOT IN (
            SELECT DISTINCT sr2.sr_ticket_number FROM store_returns sr2
        )
    GROUP BY
        c.c_customer_sk,
        cd.cd_gender,
        ca.ca_country
)
SELECT
    s.c_customer_sk,
    s.total_sales,
    s.total_store_return,
    s.total_web_return,
    s.purchase_type,
    CASE WHEN s.total_sales > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
    (SELECT MAX(ca3.ca_zip) FROM customer_address ca3 WHERE ca3.ca_state = ca.ca_state) AS max_zip_state,
    l.total_ws_qty
FROM
    sales_agg s
    JOIN customer c2 ON s.c_customer_sk = c2.c_customer_sk
    JOIN customer_address ca ON c2.c_current_addr_sk = ca.ca_address_sk
    JOIN LATERAL (
        SELECT SUM(ws2.ws_quantity) AS total_ws_qty
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = s.c_customer_sk
    ) l ON TRUE
ORDER BY
    s.total_sales DESC
LIMIT 100
