WITH base AS (
    SELECT
        cp.cp_department,
        td.t_shift,
        cs.cs_ext_sales_price        AS catalog_sales,
        ss.ss_ext_sales_price        AS store_sales,
        ws.ws_ext_sales_price        AS web_sales,
        sr.sr_return_amt             AS store_return,
        ss.ss_net_profit             AS store_profit,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN time_dim td_ret
        ON sr.sr_return_time_sk = td_ret.t_time_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    WHERE td.t_shift = 'first'
      AND td.t_hour BETWEEN 8 AND 16
      AND p_ss.p_discount_active = 'Y'
      AND cp.cp_department = 'Electronics'
      AND wp.wp_type = 'home'
      AND wsite.web_state = 'CA'
      AND ss.ss_quantity > 5
      AND sr.sr_return_quantity < 10
      AND cs.cs_ext_sales_price > 1000
),
agg AS (
    SELECT
        cp_department,
        t_shift,
        SUM(catalog_sales)        AS total_catalog_sales,
        SUM(store_sales)          AS total_store_sales,
        SUM(web_sales)            AS total_web_sales,
        SUM(store_return)         AS total_store_return,
        SUM(store_profit)         AS total_store_profit,
        CASE WHEN SUM(store_profit) > 0 THEN 'Overall Profitable' ELSE 'Overall Loss' END AS overall_profit_category,
        GROUPING(cp_department)   AS g_dept,
        GROUPING(t_shift)         AS g_shift
    FROM base
    GROUP BY ROLLUP (cp_department, t_shift)
)
SELECT
    cp_department,
    t_shift,
    total_catalog_sales,
    total_store_sales,
    total_web_sales,
    total_store_return,
    total_store_profit,
    overall_profit_category,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_store_sales DESC) AS sales_rank
FROM agg
WHERE t_shift IS NOT NULL
ORDER BY cp_department, sales_rank
LIMIT 100
