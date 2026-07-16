WITH 
store_daily AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        d.d_date_sk,
        d.d_date,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_quantity) AS store_quantity,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY d.d_date) AS day_seq
    FROM store s
    LEFT JOIN store_sales ss
        ON s.s_store_sk = ss.ss_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, s.s_store_name, d.d_date_sk, d.d_date
),
web_daily AS (
    SELECT 
        ws.ws_web_page_sk,
        wp.wp_url,
        d.d_date_sk,
        d.d_date,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        SUM(ws.ws_quantity) AS web_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_page_sk ORDER BY d.d_date) AS day_seq
    FROM web_sales ws
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_web_page_sk, wp.wp_url, d.d_date_sk, d.d_date
),
catalog_daily AS (
    SELECT 
        cs.cs_catalog_page_sk,
        cp.cp_catalog_page_number,
        d.d_date_sk,
        d.d_date,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        SUM(cs.cs_quantity) AS catalog_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_catalog_page_sk ORDER BY d.d_date) AS day_seq,
        COALESCE(cc.cc_name, 'UNKNOWN') AS call_center_name
    FROM catalog_sales cs
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_catalog_page_sk, cp.cp_catalog_page_number, d.d_date_sk, d.d_date, cc.cc_name
),
promo_active AS (
    SELECT p.p_item_sk, d.d_date_sk
    FROM promotion p
    JOIN date_dim d
      ON d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
)
SELECT *
FROM (
    SELECT 
        'store' AS channel,
        sd.s_store_sk AS entity_sk,
        sd.s_store_name AS entity_name,
        sd.d_date,
        sd.store_net_paid,
        sd.store_net_profit,
        sd.distinct_customers,
        sd.store_quantity,
        NULL AS page_url,
        NULL AS catalog_page_number,
        NULL AS call_center_name,
        CONCAT(sd.s_store_name, ' - ', CAST(sd.d_date AS varchar)) AS entity_display,
        CASE WHEN sd.store_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_status,
        (SELECT SUM(sd2.store_net_profit) 
         FROM store_daily sd2 
         WHERE sd2.s_store_sk = sd.s_store_sk 
           AND sd2.d_date BETWEEN DATE_ADD('day', -6, sd.d_date) AND sd.d_date) AS rolling_7d_net_profit,
        CASE WHEN EXISTS (
            SELECT 1 
            FROM store_sales ss
            JOIN promo_active pa ON ss.ss_item_sk = pa.p_item_sk AND ss.ss_sold_date_sk = pa.d_date_sk
            WHERE ss.ss_store_sk = sd.s_store_sk AND ss.ss_sold_date_sk = sd.d_date_sk
        ) THEN 1 ELSE 0 END AS promo_flag
    FROM store_daily sd

    UNION ALL

    SELECT 
        'web' AS channel,
        wd.ws_web_page_sk AS entity_sk,
        wd.wp_url AS entity_name,
        wd.d_date,
        wd.web_net_paid,
        wd.web_net_profit,
        wd.distinct_customers,
        wd.web_quantity,
        wd.wp_url,
        NULL,
        NULL,
        CONCAT(wd.wp_url, ' - ', CAST(wd.d_date AS varchar)) AS entity_display,
        CASE WHEN wd.web_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END,
        (SELECT SUM(wd2.web_net_profit) 
         FROM web_daily wd2 
         WHERE wd2.ws_web_page_sk = wd.ws_web_page_sk 
           AND wd2.d_date BETWEEN DATE_ADD('day', -6, wd.d_date) AND wd.d_date) AS rolling_7d_net_profit,
        CASE WHEN EXISTS (
            SELECT 1 
            FROM web_sales ws
            JOIN promo_active pa ON ws.ws_item_sk = pa.p_item_sk AND ws.ws_sold_date_sk = pa.d_date_sk
            WHERE ws.ws_web_page_sk = wd.ws_web_page_sk AND ws.ws_sold_date_sk = wd.d_date_sk
        ) THEN 1 ELSE 0 END AS promo_flag
    FROM web_daily wd

    UNION ALL

    SELECT 
        'catalog' AS channel,
        cd.cs_catalog_page_sk AS entity_sk,
        CAST(cd.cp_catalog_page_number AS varchar) AS entity_name,
        cd.d_date,
        cd.catalog_net_paid,
        cd.catalog_net_profit,
        cd.distinct_customers,
        cd.catalog_quantity,
        NULL,
        cd.cp_catalog_page_number,
        cd.call_center_name,
        CONCAT('CatalogPage ', CAST(cd.cp_catalog_page_number AS varchar), ' - ', CAST(cd.d_date AS varchar)) AS entity_display,
        CASE WHEN cd.catalog_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END,
        (SELECT SUM(cd2.catalog_net_profit) 
         FROM catalog_daily cd2 
         WHERE cd2.cs_catalog_page_sk = cd.cs_catalog_page_sk 
           AND cd2.d_date BETWEEN DATE_ADD('day', -6, cd.d_date) AND cd.d_date) AS rolling_7d_net_profit,
        CASE WHEN EXISTS (
            SELECT 1 
            FROM catalog_sales cs
            JOIN promo_active pa ON cs.cs_item_sk = pa.p_item_sk AND cs.cs_sold_date_sk = pa.d_date_sk
            WHERE cs.cs_catalog_page_sk = cd.cs_catalog_page_sk AND cs.cs_sold_date_sk = cd.d_date_sk
        ) THEN 1 ELSE 0 END AS promo_flag
    FROM catalog_daily cd
) t
ORDER BY t.channel, t.entity_name, t.d_date
