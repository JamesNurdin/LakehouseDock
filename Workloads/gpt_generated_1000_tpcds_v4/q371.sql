WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        ws.ws_promo_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt,
        AVG(ws.ws_quantity) AS avg_quantity,
        CASE
            WHEN p.p_discount_active = 'Y' THEN 'Active'
            ELSE 'Inactive'
        END AS promo_status
    FROM tpcds.web_sales ws
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        ws.ws_ship_cdemo_sk BETWEEN 200000 AND 300000
        AND ws.ws_quantity > 0
        AND ws.ws_ext_sales_price > 0
        AND ws.ws_sold_date_sk >= 2450000
        AND ws.ws_sold_date_sk <= 2453650
        AND p.p_cost > 500
    GROUP BY
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        ws.ws_promo_sk,
        CASE
            WHEN p.p_discount_active = 'Y' THEN 'Active'
            ELSE 'Inactive'
        END
)
SELECT
    site.web_name,
    page.wp_type,
    agg.promo_status,
    agg.total_net_profit,
    agg.total_discount,
    agg.sales_cnt,
    agg.avg_quantity,
    RANK() OVER (ORDER BY agg.total_net_profit DESC) AS profit_rank,
    SUM(agg.total_net_profit) OVER (PARTITION BY site.web_state) AS state_total_profit
FROM sales_agg agg
JOIN tpcds.web_site site
    ON agg.ws_web_site_sk = site.web_site_sk
JOIN tpcds.web_page page
    ON agg.ws_web_page_sk = page.wp_web_page_sk
WHERE EXISTS (
    SELECT 1
    FROM tpcds.promotion p2
    WHERE p2.p_promo_sk = agg.ws_promo_sk
      AND p2.p_channel_email = 'Y'
      AND p2.p_response_target = 1
)
  AND site.web_state IN ('CA', 'TX', 'NY')
  AND site.web_close_date_sk > 2445000
  AND page.wp_type = 'Content'
ORDER BY agg.total_net_profit DESC
LIMIT 100
