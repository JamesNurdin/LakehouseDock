WITH filtered_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        i.i_color,
        i.i_size,
        i.i_product_name
    FROM tpcds.web_sales ws
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_color, '^red|blue|green$')
      AND i.i_product_name LIKE '%COOL%'
)
SELECT
    concat(i_color, '_', i_size) AS color_size,
    CASE WHEN ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
    sum(ws_net_paid) AS total_paid,
    avg(ws_net_profit) AS avg_profit,
    regexp_extract(i_product_name, '([A-Z]+)', 1) AS product_prefix
FROM filtered_sales
GROUP BY
    concat(i_color, '_', i_size),
    CASE WHEN ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END,
    regexp_extract(i_product_name, '([A-Z]+)', 1)
ORDER BY total_paid DESC
LIMIT 100
