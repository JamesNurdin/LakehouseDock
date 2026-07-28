WITH rs AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        web.web_city,
        web.web_state,
        regexp_extract(web.web_city, '^([A-Za-z]+)', 1) AS city_first_word,
        substring(web.web_city, 1, 5) AS city_prefix,
        web.web_city || ', ' || web.web_state AS location
    FROM web_sales ws
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
    JOIN web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    WHERE regexp_like(web.web_city, '^S.*')
      AND web.web_city LIKE '%Spring%'
)
SELECT
    location,
    city_first_word,
    city_prefix,
    SUM(wr_return_quantity) AS total_return_qty,
    SUM(wr_net_loss) AS total_net_loss,
    SUM(ws_ext_sales_price) AS total_sales_amount
FROM rs
GROUP BY location, city_first_word, city_prefix
ORDER BY total_net_loss DESC
LIMIT 100
