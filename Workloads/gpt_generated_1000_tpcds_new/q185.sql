WITH site_sales AS (
    SELECT
        wsite.web_site_sk,
        wsite.web_name,
        -- extract the domain (e.g., https://www.example.com) from the page URL
        regexp_extract(wp.wp_url, '(https?://[^/]+)/', 1) AS page_domain,
        -- concatenate city and state for possible downstream use
        concat(wsite.web_city, ', ', wsite.web_state) AS city_state,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        web_sales ws
        INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        INNER JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE
        -- keep only pages whose URL contains the word "sports" after the protocol
        regexp_like(wp.wp_url, '^https?://[^/]*sports[^/]*')
        -- keep only web sites whose name starts with the letter "A"
        AND wsite.web_name LIKE 'A%'
    GROUP BY
        wsite.web_site_sk,
        wsite.web_name,
        regexp_extract(wp.wp_url, '(https?://[^/]+)/', 1),
        concat(wsite.web_city, ', ', wsite.web_state)
)
SELECT
    web_name,
    page_domain,
    city_state,
    total_profit,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rank_by_profit
FROM
    site_sales
ORDER BY
    total_profit DESC
