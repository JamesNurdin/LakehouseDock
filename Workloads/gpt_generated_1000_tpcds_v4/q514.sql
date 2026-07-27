WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_class,
        i_product_name,
        regexp_extract(i_product_name, '(\\d{3})', 1) AS product_code,
        CASE WHEN regexp_like(i_product_name, '^[A-Za-z]+-[0-9]{2,}$') THEN 1 ELSE 0 END AS has_dash_code
    FROM tpcds.item
    WHERE i_product_name LIKE '%-%' 
      AND i_class LIKE 'h%'
)
SELECT
    fi.i_class,
    fi.product_code,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS store_return_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS web_return_loss,
    SUM(COALESCE(sr.sr_net_loss, 0)) + SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT fi.i_item_sk) AS distinct_items
FROM filtered_items fi
LEFT JOIN tpcds.store_sales ss
    ON ss.ss_item_sk = fi.i_item_sk
LEFT JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = fi.i_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN tpcds.web_sales ws
    ON ws.ws_item_sk = fi.i_item_sk
LEFT JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = fi.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
GROUP BY fi.i_class, fi.product_code
HAVING SUM(COALESCE(sr.sr_net_loss, 0)) + SUM(COALESCE(wr.wr_net_loss, 0)) > 0
ORDER BY total_return_loss DESC
LIMIT 100
