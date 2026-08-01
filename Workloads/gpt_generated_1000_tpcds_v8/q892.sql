WITH promo_store AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        AVG(ss.ss_sales_price) AS avg_store_price,
        COUNT(*) AS cnt_store_sales
    FROM tpcds.promotion p
    JOIN tpcds.store_sales ss
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'N'
      AND p.p_discount_active = 'Y'
      AND ss.ss_sales_price BETWEEN 2.00 AND 144.09
      AND ss.ss_quantity >= 2
      AND ss.ss_ext_discount_amt < 400.00
      AND ss.ss_wholesale_cost > 100.00
    GROUP BY CUBE (p.p_promo_sk, p.p_promo_id, p.p_promo_name)
),
promo_web AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        wp.wp_web_page_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        AVG(ws.ws_sales_price) AS avg_web_price,
        COUNT(*) AS cnt_web_sales
    FROM tpcds.promotion p
    JOIN tpcds.web_sales ws
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'content'
      AND ws.ws_net_paid_inc_tax > 1000.00
      AND ws.ws_coupon_amt = 0.00
      AND ws.ws_quantity BETWEEN 1 AND 5
      AND ws.ws_ext_discount_amt < 300.00
      AND ws.ws_wholesale_cost > 50.00
    GROUP BY CUBE (p.p_promo_sk, p.p_promo_id, p.p_promo_name, wp.wp_web_page_id)
),
intersect_promos AS (
    SELECT p_promo_sk FROM promo_store
    INTERSECT
    SELECT p_promo_sk FROM promo_web
)
SELECT
    i.p_promo_sk,
    p.p_promo_name,
    COALESCE(ps.total_store_sales, 0) AS total_store_sales,
    COALESCE(pw.total_web_sales, 0) AS total_web_sales,
    ROW_NUMBER() OVER (PARTITION BY i.p_promo_sk ORDER BY COALESCE(pw.total_web_sales, 0) DESC) AS web_sales_rank,
    COUNT(*) OVER (PARTITION BY i.p_promo_sk) AS promo_occurrences
FROM intersect_promos i
JOIN tpcds.promotion p
  ON p.p_promo_sk = i.p_promo_sk
LEFT JOIN promo_store ps
  ON ps.p_promo_sk = i.p_promo_sk
LEFT JOIN promo_web pw
  ON pw.p_promo_sk = i.p_promo_sk
WHERE NOT EXISTS (
        SELECT 1 FROM tpcds.web_sales ws2
        WHERE ws2.ws_promo_sk = i.p_promo_sk
          AND ws2.ws_ship_customer_sk = 1633483
    )
  AND EXISTS (
        SELECT 1 FROM tpcds.store_sales ss2
        WHERE ss2.ss_promo_sk = i.p_promo_sk
          AND ss2.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    )
ORDER BY total_web_sales DESC, total_store_sales DESC
LIMIT 100
