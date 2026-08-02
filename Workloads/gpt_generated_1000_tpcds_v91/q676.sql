WITH sampled_ss AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),

promo_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        d_ss.d_year AS d_year,
        SUM(ss.ss_net_profit) AS store_sales_net_profit,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS web_sales_net_profit,
        SUM(ss.ss_quantity) AS store_sales_quantity,
        SUM(COALESCE(ws.ws_quantity, 0)) AS web_sales_quantity,
        SUM(ss.ss_net_profit) + SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit
    FROM sampled_ss ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_ss.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    WHERE
        d_ss.d_year = 2001
        AND d_ss.d_qoy = 2
        AND s.s_state = 'TX'
        AND p.p_discount_active = 'Y'
        AND cc.cc_market_manager = 'Mark Camp'
        AND wp.wp_max_ad_count = 2
        AND ss.ss_quantity > 5
        AND (ws.ws_net_profit IS NULL OR ws.ws_net_profit > 0)
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        d_ss.d_year
)

SELECT
    p_promo_id,
    p_promo_name,
    d_year,
    store_sales_net_profit,
    web_sales_net_profit,
    store_sales_quantity,
    web_sales_quantity,
    total_net_profit,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
    CASE
        WHEN total_net_profit > 1000000 THEN 'HIGH'
        WHEN total_net_profit > 500000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM promo_agg
ORDER BY total_net_profit DESC
LIMIT 100
