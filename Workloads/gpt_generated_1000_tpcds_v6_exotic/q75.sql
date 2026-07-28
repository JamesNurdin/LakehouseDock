WITH base AS (
    SELECT
        i.i_brand,
        ws.ws_web_site_sk,
        ws.ws_coupon_amt,
        ss.ss_net_paid,
        ws.ws_net_paid,
        ss.ss_net_profit,
        ws.ws_net_profit,
        wp.wp_autogen_flag,
        wp.wp_link_count,
        web_site.web_country
    FROM item i
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'
      AND i.i_rec_end_date <= DATE '2001-12-31'
      AND wp.wp_autogen_flag = 'N'
      AND wp.wp_link_count > 5
      AND ws.ws_coupon_amt > 1000
),
agg AS (
    SELECT
        i_brand,
        web_country,
        SUM(ss_net_paid + ws_net_paid) AS total_net_paid,
        SUM(ss_net_profit + ws_net_profit) AS total_profit,
        COUNT(*) AS transaction_count
    FROM base
    GROUP BY GROUPING SETS (
        (i_brand, web_country),
        (i_brand),
        (web_country),
        ()
    )
)
SELECT
    i_brand,
    web_country,
    total_net_paid,
    total_profit,
    transaction_count,
    CASE
        WHEN total_profit > 50000 THEN 'HIGH'
        WHEN total_profit > 20000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_level,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_net_paid DESC) AS brand_sales_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
