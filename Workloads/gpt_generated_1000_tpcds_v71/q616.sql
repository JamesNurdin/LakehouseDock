WITH store_return_agg AS (
    SELECT
        'store_return' AS source,
        concat(s.s_store_name, ' (', s.s_state, ')') AS entity,
        d.d_year AS year,
        sum(sr.sr_net_loss) AS total_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2020
      AND regexp_like(s.s_manager, '.* Smith$')
      AND s.s_market_manager LIKE '%Stone%'
    GROUP BY concat(s.s_store_name, ' (', s.s_state, ')'), d.d_year
),
web_sales_agg AS (
    SELECT
        'web_sales' AS source,
        wp.wp_url AS entity,
        d.d_year AS year,
        sum(ws.ws_net_profit) AS total_amount
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2020
      AND regexp_like(wp.wp_url, '^https?://example\\.com')
      AND wp.wp_type LIKE '%article%'
      AND regexp_extract(wp.wp_url, '^https?://([^/]+)/', 1) = 'example.com'
    GROUP BY wp.wp_url, d.d_year
)
SELECT source, entity, year, total_amount
FROM store_return_agg
UNION ALL
SELECT source, entity, year, total_amount
FROM web_sales_agg
ORDER BY total_amount DESC
LIMIT 100
