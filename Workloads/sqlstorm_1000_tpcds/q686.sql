SELECT
    d_year,
    month,
    i_category,
    channel,
    promo_name,
    total_net_profit,
    total_sales,
    total_transactions,
    store_state,
    web_page_type,
    web_state,
    call_center_state,
    catalog_page_type,
    RANK() OVER (PARTITION BY d_year, channel ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        d.d_year AS d_year,
        d.d_moy AS month,
        i.i_category,
        s.channel,
        p.p_promo_name AS promo_name,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.ext_sales_price) AS total_sales,
        COUNT(*) AS total_transactions,
        MAX(st.s_state) AS store_state,
        MAX(wp.wp_type) AS web_page_type,
        MAX(wsite.web_state) AS web_state,
        MAX(cc.cc_state) AS call_center_state,
        MAX(cp.cp_type) AS catalog_page_type
    FROM (
        SELECT
            ss_sold_date_sk AS date_sk,
            ss_item_sk AS item_sk,
            ss_promo_sk AS promo_sk,
            ss_store_sk AS store_sk,
            NULL AS web_page_sk,
            NULL AS web_site_sk,
            NULL AS call_center_sk,
            NULL AS catalog_page_sk,
            'store' AS channel,
            ss_net_profit AS net_profit,
            ss_ext_sales_price AS ext_sales_price
        FROM store_sales
        UNION ALL
        SELECT
            ws_sold_date_sk,
            ws_item_sk,
            ws_promo_sk,
            NULL,
            ws_web_page_sk,
            ws_web_site_sk,
            NULL,
            NULL,
            'web',
            ws_net_profit,
            ws_ext_sales_price
        FROM web_sales
        UNION ALL
        SELECT
            cs_sold_date_sk,
            cs_item_sk,
            cs_promo_sk,
            NULL,
            NULL,
            NULL,
            cs_call_center_sk,
            cs_catalog_page_sk,
            'catalog',
            cs_net_profit,
            cs_ext_sales_price
        FROM catalog_sales
    ) s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN store st ON s.store_sk = st.s_store_sk
    LEFT JOIN web_page wp ON s.web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite ON s.web_site_sk = wsite.web_site_sk
    LEFT JOIN call_center cc ON s.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON s.catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON s.promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY d.d_year, d.d_moy, i.i_category, s.channel, p.p_promo_name
) agg
ORDER BY total_net_profit DESC
