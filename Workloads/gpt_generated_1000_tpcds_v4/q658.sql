WITH cs AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        d.d_year,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        REGEXP_EXTRACT(cc.cc_name, '(\\d+)$', 1) AS name_suffix,
        SUBSTR(cc.cc_name, 1, 5) AS name_prefix
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(p.p_promo_name, '(?i)discount')
      AND REGEXP_LIKE(cc.cc_name, '^C.*\\d$')
      AND cc.cc_city LIKE '%York%'
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        d.d_year,
        REGEXP_EXTRACT(cc.cc_name, '(\\d+)$', 1),
        SUBSTR(cc.cc_name, 1, 5)
)
SELECT
    cs.cc_call_center_sk,
    cs.cc_name,
    CONCAT(cs.cc_city, ', ', cs.cc_state) AS location,
    cs.name_prefix,
    cs.name_suffix,
    cs.total_profit,
    cs.sales_cnt,
    (cs.total_profit / cs.sales_cnt) AS avg_profit_per_sale,
    (
        SELECT SUM(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    ) AS year_total_profit
FROM cs
WHERE cs.total_profit > (
    SELECT AVG(total_profit) FROM cs
)
ORDER BY cs.total_profit DESC
LIMIT 100
