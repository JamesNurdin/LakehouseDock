WITH sales_agg AS (
    SELECT
        ws_web_page_sk,
        ws_web_site_sk,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM tpcds.web_sales
    WHERE ws_quantity > 0
      AND ws_net_profit > 0
      AND ws_ext_sales_price > 0
    GROUP BY ws_web_page_sk, ws_web_site_sk
)
SELECT
    wsag.ws_web_site_sk,
    site.web_site_id,
    site.web_name,
    wp.wp_web_page_sk,
    wp.wp_url,
    wp.wp_type,
    wsag.total_net_profit,
    wsag.total_sales,
    wsag.total_quantity,
    RANK() OVER (PARTITION BY site.web_site_id ORDER BY wsag.total_net_profit DESC) AS profit_rank
FROM sales_agg wsag
JOIN tpcds.web_page wp
  ON wsag.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site site
  ON wsag.ws_web_site_sk = site.web_site_sk
WHERE wp.wp_type IN ('protected', 'order')
  AND wp.wp_rec_end_date > DATE '2000-01-01'
  AND wp.wp_char_count > 1000
  AND site.web_mkt_id IN (1, 2, 3)
  AND site.web_state = 'CA'
ORDER BY site.web_site_id, profit_rank
LIMIT 100
