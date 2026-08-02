WITH web_agg AS (
    SELECT
        'web' AS source_type,
        concat('WS_', web_site.web_site_id) AS location_id,
        date_dim.d_year AS year,
        sum(ws_net_profit) AS total_amount
    FROM web_sales
    JOIN date_dim
        ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    JOIN web_page
        ON web_sales.ws_web_page_sk = web_page.wp_web_page_sk
    JOIN web_site
        ON web_sales.ws_web_site_sk = web_site.web_site_sk
    WHERE regexp_like(web_page.wp_url, '^https?://[^/]*product')
      AND substr(web_page.wp_url, 1, 5) = 'https'
      AND web_site.web_zip LIKE '9%'
    GROUP BY web_site.web_site_id, date_dim.d_year
),
store_agg AS (
    SELECT
        'store' AS source_type,
        concat('ST_', store.s_store_id) AS location_id,
        date_dim.d_year AS year,
        sum(sr_net_loss) AS total_amount
    FROM store_returns
    JOIN date_dim
        ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
    JOIN store
        ON store_returns.sr_store_sk = store.s_store_sk
    JOIN customer_address
        ON store_returns.sr_addr_sk = customer_address.ca_address_sk
    WHERE store.s_store_name LIKE '%Mall%'
      AND regexp_like(customer_address.ca_city, '^A')
      AND substr(customer_address.ca_city, 1, 1) = 'A'
    GROUP BY store.s_store_id, date_dim.d_year
),
combined AS (
    SELECT * FROM web_agg
    UNION ALL
    SELECT * FROM store_agg
)
SELECT
    combined.source_type,
    combined.location_id,
    combined.year,
    combined.total_amount
FROM combined
WHERE combined.location_id NOT IN (
    SELECT concat('WS_', web_site.web_site_id)
    FROM web_site
    WHERE web_site.web_zip LIKE '7%'
)
ORDER BY
    combined.source_type,
    combined.total_amount DESC,
    combined.year
