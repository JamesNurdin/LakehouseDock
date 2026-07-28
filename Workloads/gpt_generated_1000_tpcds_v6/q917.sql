WITH sales_union AS (
    SELECT
        ss.ss_net_profit AS net_amount,
        ss.ss_sold_date_sk   AS date_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_net_profit AS net_amount,
        ws.ws_sold_date_sk   AS date_sk
    FROM web_sales ws
),
agg AS (
    SELECT
        cc.cc_city,
        cc.cc_state,
        d.d_year,
        SUM(s.net_amount)                AS total_net_amount,
        GROUPING(cc.cc_city)             AS g_city,
        GROUPING(d.d_year)               AS g_year
    FROM sales_union s
    JOIN date_dim d   ON s.date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE regexp_like(cc.cc_city, '^A')
      AND cc.cc_state LIKE 'C%'
    GROUP BY ROLLUP (cc.cc_city, cc.cc_state, d.d_year)
)
SELECT
    CASE WHEN g_city = 1 THEN 'All Cities' ELSE concat(cc_city, ', ', cc_state) END AS location,
    d_year,
    total_net_amount,
    CASE WHEN g_city = 1 THEN NULL ELSE substring(cc_city, 1, 3) END AS city_prefix
FROM agg
ORDER BY total_net_amount DESC
LIMIT 100
