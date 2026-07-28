WITH catalog_data AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_net_paid AS net_paid,
        cr.cr_return_amount AS return_amount,
        c.c_customer_id,
        hd.hd_income_band_sk,
        td.t_hour,
        cc.cc_name,
        'catalog' AS src
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    WHERE c.c_salutation = 'Mr.'
      AND c.c_birth_year = 1975
      AND td.t_hour = 14
),
web_data AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_net_paid AS net_paid,
        wr.wr_return_amt AS return_amount,
        c.c_customer_id,
        hd.hd_income_band_sk,
        td.t_hour,
        ws_site.web_name,
        'web' AS src
    FROM web_sales ws
    JOIN web_site ws_site
      ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    WHERE ws_site.web_gmt_offset = -5.00
      AND c.c_salutation = 'Mrs.'
      AND td.t_hour = 16
)
SELECT
    src,
    COUNT(DISTINCT order_number) AS orders_cnt,
    SUM(net_paid) AS total_net_paid,
    AVG(return_amount) AS avg_return_amount,
    MIN(net_paid) AS min_net_paid,
    MAX(net_paid) AS max_net_paid
FROM (
    SELECT src, order_number, net_paid, return_amount FROM catalog_data
    UNION ALL
    SELECT src, order_number, net_paid, return_amount FROM web_data
) AS combined
GROUP BY src
ORDER BY total_net_paid DESC
LIMIT 100
