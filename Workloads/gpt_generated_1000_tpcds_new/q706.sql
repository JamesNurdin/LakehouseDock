WITH promo_info AS (
    SELECT p_promo_sk,
           p_promo_name,
           p_discount_active
    FROM promotion
    WHERE p_discount_active = 'Y'
)
SELECT
    src.sales_type,
    src.sales_date_sk,
    src.promo_sk,
    promo_info.p_promo_name,
    src.total_sales,
    (
        SELECT SUM(cs_ext_sales_price)
        FROM catalog_sales cs
        WHERE cs.cs_promo_sk = src.promo_sk
    ) AS catalog_sales_total_for_promo,
    (
        SELECT COUNT(DISTINCT cs_order_number)
        FROM catalog_sales cs
        WHERE cs.cs_promo_sk = src.promo_sk
    ) AS catalog_order_cnt
FROM (
    SELECT
        'catalog' AS sales_type,
        cs.cs_sold_date_sk AS sales_date_sk,
        cs.cs_promo_sk AS promo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        cs.cs_warehouse_sk
    FROM catalog_sales cs
    FULL OUTER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450820
    GROUP BY cs.cs_sold_date_sk, cs.cs_promo_sk, cs.cs_warehouse_sk

    UNION ALL

    SELECT
        'web' AS sales_type,
        ws.ws_sold_date_sk AS sales_date_sk,
        ws.ws_promo_sk AS promo_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ws.ws_warehouse_sk
    FROM web_sales ws
    FULL OUTER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450820
    GROUP BY ws.ws_sold_date_sk, ws.ws_promo_sk, ws.ws_warehouse_sk
) src
JOIN promo_info
    ON promo_info.p_promo_sk = src.promo_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs
    WHERE cs.cs_promo_sk = src.promo_sk
      AND cs.cs_ext_sales_price > 0
)
ORDER BY src.sales_date_sk, src.sales_type
