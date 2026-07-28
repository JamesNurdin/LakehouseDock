WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        cd.cd_gender,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
        AVG(ws.ws_ext_discount_amt) AS avg_web_discount
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_current_price > 30
      AND cd.cd_dep_college_count = 0
      AND ss.ss_sold_date_sk >= 2451545
      AND ws.ws_net_paid_inc_ship > 500
    GROUP BY GROUPING SETS (
        (i.i_item_sk, i.i_brand, cd.cd_gender),
        (i.i_brand, cd.cd_gender),
        (i.i_brand)
    )
)
SELECT
    s.i_brand,
    s.cd_gender,
    SUM(s.total_sales) AS total_sales,
    AVG(s.avg_store_discount) AS avg_store_discount,
    AVG(s.avg_web_discount) AS avg_web_discount
FROM sales_agg s
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss2
    WHERE ss2.ss_item_sk = s.i_item_sk
      AND ss2.ss_coupon_amt > 1000
)
GROUP BY ROLLUP (s.i_brand, s.cd_gender)
HAVING SUM(s.total_sales) > 10000
ORDER BY total_sales DESC
LIMIT 100
