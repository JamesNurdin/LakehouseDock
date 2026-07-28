WITH promo_filtered AS (
    SELECT p.p_promo_sk,
           p.p_promo_name
    FROM   promotion p
    WHERE  regexp_like(p.p_promo_name, '.*Clearance.*')
),
web_match AS (
    SELECT DISTINCT wp.wp_web_page_sk,
                    wp.wp_url,
                    wp.wp_creation_date_sk
    FROM   web_page wp
    WHERE  wp.wp_url LIKE '%sale%'
)
SELECT
    cc.cc_call_center_id,
    d.d_year,
    SUM(cs.cs_net_profit)               AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number)  AS orders,
    MIN(cc.cc_name)                     AS example_cc_name,
    regexp_extract(MIN(cc.cc_name), '(\\w+)') AS first_word_cc_name
FROM   catalog_sales cs
JOIN   date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
JOIN   call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN   promo_filtered p         ON cs.cs_promo_sk = p.p_promo_sk
WHERE  cc.cc_hours LIKE '8AM-%'                     -- hours start at 8AM
  AND EXISTS (
        SELECT 1
        FROM   web_match wm
        JOIN   date_dim d2 ON wm.wp_creation_date_sk = d2.d_date_sk
        WHERE  d2.d_year = d.d_year                     -- same calendar year
          AND  wm.wp_url LIKE CONCAT('%', REPLACE(cc.cc_name, ' ', ''), '%')
    )
GROUP BY
    cc.cc_call_center_id,
    d.d_year
HAVING SUM(cs.cs_net_profit) > 0
ORDER BY
    total_net_profit DESC
LIMIT 20
