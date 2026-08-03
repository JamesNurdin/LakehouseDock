WITH store_sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS store_item_net_profit,
        COUNT(*) AS store_item_sales_cnt
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2451910 AND 2451915
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
),
base_agg AS (
    SELECT
        i.i_brand,
        s.s_store_name,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(sa.store_item_net_profit) AS total_store_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd_cs ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_cr_refunded ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
    JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN catalog_page cp_cr ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
    JOIN store_sales_agg sa ON sa.ss_item_sk = i.i_item_sk
    JOIN store s ON s.s_store_sk = sa.ss_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND wsite.web_city = 'Glenwood'
    GROUP BY CUBE(i.i_brand, s.s_store_name, d.d_year)
)
SELECT
    i_brand,
    s_store_name,
    d_year,
    total_catalog_sales,
    total_web_sales,
    total_store_profit,
    catalog_order_cnt,
    CASE WHEN total_catalog_sales > 100000 THEN 'High' ELSE 'Low' END AS sales_level,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_store_profit DESC) AS profit_rank
FROM base_agg
ORDER BY total_store_profit DESC
LIMIT 100
