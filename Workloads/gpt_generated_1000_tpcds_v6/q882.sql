WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 0
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_net_loss,
        wr.wr_item_sk,
        wr.wr_web_page_sk,
        wr.wr_reason_sk
    FROM web_returns wr
    WHERE wr.wr_net_loss > 0
)
SELECT
    i.i_brand,
    regexp_extract(i.i_brand, '(\\d+)$', 1) AS brand_number,
    count(DISTINCT s.ws_order_number) AS orders,
    sum(s.ws_ext_sales_price) AS total_sales,
    sum(COALESCE(r.wr_net_loss, 0)) AS total_return_loss,
    sum(COALESCE(r.wr_net_loss, 0)) / nullif(sum(s.ws_ext_sales_price), 0) AS loss_ratio,
    max(wp.wp_url) FILTER (WHERE wp.wp_url LIKE '%promo%') AS sample_promo_url
FROM sales s
JOIN item i
    ON s.ws_item_sk = i.i_item_sk
LEFT JOIN returns r
    ON s.ws_order_number = r.wr_order_number
   AND s.ws_item_sk = r.wr_item_sk
LEFT JOIN web_page wp
    ON s.ws_web_page_sk = wp.wp_web_page_sk
WHERE regexp_like(i.i_brand, '^.*\\d+$')
  AND wp.wp_url LIKE '%example.com/%'
GROUP BY i.i_brand, regexp_extract(i.i_brand, '(\\d+)$', 1)
HAVING sum(s.ws_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
