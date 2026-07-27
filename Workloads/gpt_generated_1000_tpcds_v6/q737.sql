WITH avg_discount AS (
    SELECT avg(ws_ext_discount_amt) AS avg_disc
    FROM web_sales
),

bill_sales AS (
    SELECT
        p.p_promo_name,
        cd.cd_credit_rating AS demo_attr,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        'Bill' AS source
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND p.p_channel_tv = 'Y'
      AND ws.ws_ext_sales_price > (SELECT avg_disc FROM avg_discount)
    GROUP BY p.p_promo_name, cd.cd_credit_rating
    HAVING SUM(ws.ws_ext_sales_price) > 10000
),

ship_sales AS (
    SELECT
        p.p_promo_name,
        cd.cd_marital_status AS demo_attr,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        'Ship' AS source
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE cd.cd_marital_status = 'M'
      AND p.p_channel_demo = 'N'
      AND EXISTS (
          SELECT 1 FROM web_sales ws2
          WHERE ws2.ws_promo_sk = ws.ws_promo_sk
            AND ws2.ws_ext_discount_amt > 5
      )
    GROUP BY p.p_promo_name, cd.cd_marital_status
    HAVING SUM(ws.ws_ext_sales_price) > 15000
)

SELECT
    p_promo_name,
    source,
    demo_attr,
    total_sales,
    order_cnt,
    avg_discount,
    RANK() OVER (PARTITION BY source ORDER BY total_sales DESC) AS promo_rank
FROM (
    SELECT * FROM bill_sales
    UNION ALL
    SELECT * FROM ship_sales
) combined
ORDER BY source, promo_rank
LIMIT 100
