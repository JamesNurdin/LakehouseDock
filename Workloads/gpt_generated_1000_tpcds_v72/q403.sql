WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_net_loss,
        wr.wr_return_ship_cost,
        ws.ws_web_site_sk,
        wr.wr_order_number,
        wr.wr_item_sk
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
)
SELECT
    ws_site.web_site_id,
    ws_site.web_city,
    ws_site.web_state,
    concat(ws_site.web_city, '-', substring(ws_site.web_state, 1, 2)) AS city_state_code,
    regexp_extract(ws_site.web_zip, '(\\d{3})', 1) AS zip_prefix,
    sum(fr.wr_net_loss) AS total_net_loss,
    count(*) AS returns_count,
    avg(fr.wr_return_ship_cost) AS avg_ship_cost
FROM filtered_returns fr
JOIN web_site ws_site
    ON fr.ws_web_site_sk = ws_site.web_site_sk
WHERE ws_site.web_zip LIKE '4%'
  AND regexp_like(ws_site.web_city, '^New')
GROUP BY
    ws_site.web_site_id,
    ws_site.web_city,
    ws_site.web_state,
    concat(ws_site.web_city, '-', substring(ws_site.web_state, 1, 2)),
    regexp_extract(ws_site.web_zip, '(\\d{3})', 1)
ORDER BY total_net_loss DESC
LIMIT 100
