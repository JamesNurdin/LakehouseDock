/* goal: Identify the top‑performing web pages by total net profit, segmented by page type, and classify their profitability. */
WITH sales_page AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_type,
        wp.wp_max_ad_count,
        SUM(ws.ws_ext_sales_price) AS total_ext_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid_inc_ship_tax) AS avg_paid_inc_ship_tax,
        COUNT(*) AS txn_count
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_net_paid_inc_ship_tax > 500
      AND ws.ws_ext_discount_amt BETWEEN 200 AND 3000
      AND wp.wp_max_ad_count >= 1
      AND wp.wp_creation_date_sk BETWEEN 2450800 AND 2450810
    GROUP BY wp.wp_web_page_id, wp.wp_type, wp.wp_max_ad_count
)
SELECT
    wp_web_page_id,
    wp_type,
    wp_max_ad_count,
    total_ext_sales,
    total_net_profit,
    avg_paid_inc_ship_tax,
    txn_count,
    CASE
        WHEN total_net_profit > 10000 THEN 'HIGH'
        WHEN total_net_profit > 5000  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY wp_type ORDER BY total_net_profit DESC) AS type_profit_rank
FROM sales_page
ORDER BY total_net_profit DESC
LIMIT 100
