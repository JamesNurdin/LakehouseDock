WITH raw_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_promo_sk,
        d.d_date,
        s.web_site_id,
        s.web_city,
        s.web_state,
        s.web_site_sk,
        s.web_name
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE d.d_year = 2001
      AND regexp_like(s.web_name, '(Online|Store)')
),
agg_sales AS (
    SELECT
        web_site_id,
        web_city,
        web_state,
        web_site_sk,
        d_date,
        ws_sold_date_sk,
        ws_promo_sk,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws_order_number) AS orders,
        MAX(ws_ext_discount_amt) AS max_discount
    FROM raw_sales
    WHERE (web_city LIKE 'A%' OR web_city LIKE 'B%')
      AND EXISTS (
          SELECT 1 FROM promotion p
          WHERE p.p_promo_sk = raw_sales.ws_promo_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY
        web_site_id,
        web_city,
        web_state,
        web_site_sk,
        d_date,
        ws_sold_date_sk,
        ws_promo_sk
    HAVING SUM(ws_net_profit) > 5000
)
SELECT
    CONCAT(web_city, ', ', web_state) AS location,
    web_site_id,
    CAST(d_date AS VARCHAR) AS sale_date,
    total_profit,
    avg_profit,
    orders,
    max_discount,
    SUM(total_profit) OVER (PARTITION BY web_site_sk) AS site_total_profit,
    (
        SELECT COUNT(DISTINCT ws2.ws_promo_sk)
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = agg_sales.web_site_sk
          AND ws2.ws_sold_date_sk = agg_sales.ws_sold_date_sk
    ) AS distinct_promos
FROM agg_sales
ORDER BY total_profit DESC
LIMIT 100
