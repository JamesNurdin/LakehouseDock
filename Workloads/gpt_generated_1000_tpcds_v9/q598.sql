WITH cat_sales_returns AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_quantity,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
)
SELECT
    d.d_year,
    s.s_store_name,
    s.s_division_name,
    cd.cd_gender,
    SUM(cat.cs_net_paid) AS total_catalog_sales,
    SUM(cat.cr_return_amount) AS total_catalog_returns,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(wr.wr_return_amt) AS total_web_returns,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    (
        SELECT AVG(ws2.ws_net_paid)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d.d_year
    ) AS avg_web_sales_yearly
FROM date_dim d
JOIN cat_sales_returns cat
    ON cat.cs_sold_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
WHERE
    d.d_date >= DATE '2001-01-01'
    AND d.d_date <= DATE '2001-12-31'
    AND s.s_state = 'CA'
    AND s.s_zip = '43951'
    AND cd.cd_marital_status = 'M'
    AND cd.cd_dep_employed_count >= 3
    AND cat.cs_quantity > 5
    AND ws.ws_net_paid > 100
    AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_amt > 0
    )
GROUP BY
    d.d_year,
    s.s_store_name,
    s.s_division_name,
    cd.cd_gender
ORDER BY
    total_catalog_sales DESC,
    d.d_year ASC
LIMIT 100
