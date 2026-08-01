WITH joined_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_list_price,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_store_credit,
        d.d_year,
        d.d_moy,
        i.i_brand,
        i.i_category,
        p.p_discount_active
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_item_sk = i.i_item_sk
    CROSS JOIN LATERAL (
        SELECT p2.p_promo_name
        FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_discount_active = 'Y'
        LIMIT 1
    ) AS promo_name_lateral
    WHERE d.d_year = 2001
      AND d.d_moy IN (3, 4, 5)
      AND i.i_brand = 'Brand#12'
      AND ws.ws_list_price > 150.00
      AND cs.cs_quantity >= 2
      AND t.t_hour BETWEEN 9 AND 17
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_item_sk = i.i_item_sk
            AND ws2.ws_sold_date_sk = d.d_date_sk
            AND ws2.ws_list_price > 200.00
          LIMIT 1
      )
)
SELECT
    d_year,
    i_brand,
    i_category,
    COUNT(DISTINCT cs_sold_date_sk) AS days_sold,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(sr_store_credit) AS total_store_credit,
    AVG(ws_list_price) AS avg_web_list_price,
    MIN(cs_quantity) AS min_quantity,
    MAX(cs_quantity) AS max_quantity
FROM joined_data
GROUP BY d_year, i_brand, i_category
ORDER BY total_catalog_sales DESC
LIMIT 100
