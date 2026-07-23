WITH sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        wp.wp_max_ad_count,
        wsit.web_name,
        wsit.web_mkt_desc
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE d.d_year = 2001
      AND wsit.web_mkt_desc LIKE '%global%'
      AND wp.wp_max_ad_count > 0
),
site_sales AS (
    SELECT
        sd.ws_web_site_sk,
        sd.web_name,
        sd.web_mkt_desc,
        sd.ws_sold_date_sk,
        d2.d_date,
        d2.d_year,
        d2.d_month_seq,
        SUM(sd.ws_ext_sales_price) AS total_sales,
        SUM(sd.ws_net_profit) AS total_profit
    FROM sales_data sd
    JOIN date_dim d2
        ON sd.ws_sold_date_sk = d2.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d2.d_date_sk
    WHERE cp.cp_catalog_page_number IN (7, 12)
    GROUP BY
        sd.ws_web_site_sk,
        sd.web_name,
        sd.web_mkt_desc,
        sd.ws_sold_date_sk,
        d2.d_date,
        d2.d_year,
        d2.d_month_seq
)
SELECT
    ss.ws_web_site_sk,
    ss.web_name,
    ss.web_mkt_desc,
    ss.d_date,
    ss.d_year,
    ss.d_month_seq,
    ss.total_sales,
    ss.total_profit,
    RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank,
    CASE
        WHEN ss.total_profit > 100000 THEN 'HIGH'
        WHEN ss.total_profit > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    (
        SELECT MAX(cp2.cp_catalog_page_number)
        FROM catalog_page cp2
        WHERE cp2.cp_start_date_sk = ss.ws_sold_date_sk
    ) AS max_cp_number_for_date
FROM site_sales ss
ORDER BY ss.total_sales DESC
LIMIT 100
