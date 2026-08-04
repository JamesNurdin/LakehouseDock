WITH full_join AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_item_sk,
        wr.wr_returned_date_sk,
        wr.wr_web_page_sk,
        wr.wr_net_loss,
        wr.wr_order_number,
        wr.wr_item_sk
    FROM web_sales ws
    FULL OUTER JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
)
SELECT
    d.d_year,
    wp.wp_type,
    cp.cp_department,
    sum(coalesce(ws.ws_net_profit, 0)) AS total_profit,
    sum(coalesce(wr.wr_net_loss, 0)) AS total_loss,
    regexp_extract(cp.cp_description, '(\\w+)', 1) AS first_word,
    CASE WHEN cp.cp_description LIKE '%services%' THEN TRUE ELSE FALSE END AS has_services,
    count(DISTINCT url_seg) AS distinct_url_segments
FROM full_join fj
LEFT JOIN web_sales ws ON fj.ws_order_number = ws.ws_order_number AND fj.ws_item_sk = ws.ws_item_sk
LEFT JOIN web_returns wr ON fj.wr_order_number = wr.wr_order_number AND fj.wr_item_sk = wr.wr_item_sk
JOIN date_dim d ON coalesce(fj.ws_sold_date_sk, fj.wr_returned_date_sk) = d.d_date_sk
JOIN web_page wp ON coalesce(fj.ws_web_page_sk, fj.wr_web_page_sk) = wp.wp_web_page_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS t(url_seg)
WHERE regexp_like(cp.cp_description, '.*services.*')
GROUP BY
    d.d_year,
    wp.wp_type,
    cp.cp_department,
    regexp_extract(cp.cp_description, '(\\w+)', 1),
    CASE WHEN cp.cp_description LIKE '%services%' THEN TRUE ELSE FALSE END
HAVING sum(coalesce(ws.ws_net_profit, 0)) > 0

UNION DISTINCT

SELECT
    d.d_year,
    wp.wp_type,
    cp.cp_department,
    sum(coalesce(ws.ws_net_profit, 0)) AS total_profit,
    sum(coalesce(wr.wr_net_loss, 0)) AS total_loss,
    regexp_extract(cp.cp_description, '(\\w+)', 1) AS first_word,
    CASE WHEN cp.cp_description LIKE '%services%' THEN TRUE ELSE FALSE END AS has_services,
    count(DISTINCT url_seg) AS distinct_url_segments
FROM full_join fj
LEFT JOIN web_sales ws ON fj.ws_order_number = ws.ws_order_number AND fj.ws_item_sk = ws.ws_item_sk
LEFT JOIN web_returns wr ON fj.wr_order_number = wr.wr_order_number AND fj.wr_item_sk = wr.wr_item_sk
JOIN date_dim d ON coalesce(fj.ws_sold_date_sk, fj.wr_returned_date_sk) = d.d_date_sk
JOIN web_page wp ON coalesce(fj.ws_web_page_sk, fj.wr_web_page_sk) = wp.wp_web_page_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS t(url_seg)
WHERE regexp_like(cp.cp_description, '.*services.*')
GROUP BY
    d.d_year,
    wp.wp_type,
    cp.cp_department,
    regexp_extract(cp.cp_description, '(\\w+)', 1),
    CASE WHEN cp.cp_description LIKE '%services%' THEN TRUE ELSE FALSE END
HAVING sum(coalesce(wr.wr_net_loss, 0)) > 0
LIMIT 100
