WITH sales_by_store AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
    FROM
        time_dim td
        JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
        JOIN customer_demographics cd_cs ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
        JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
        LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
        LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE
        cp.cp_department = 'Electronics'
        AND sm_cs.sm_type = 'AIR'
        AND cd_cs.cd_gender = 'F'
        AND s.s_state = 'CA'
        AND td.t_hour BETWEEN 9 AND 17
        AND wp.wp_max_ad_count > 0
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_state
)

SELECT
    rnk,
    store_name,
    store_state,
    catalog_profit,
    web_profit,
    total_profit,
    distinct_web_pages,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM web_returns wr_sub
            WHERE wr_sub.wr_return_quantity > 0
            LIMIT 1
        ) THEN 'HAS_RETURNS' ELSE 'NO_RETURNS'
    END AS return_indicator
FROM (
    SELECT
        s_store_sk,
        s_store_name AS store_name,
        s_state AS store_state,
        catalog_profit,
        web_profit,
        catalog_profit + web_profit AS total_profit,
        distinct_web_pages,
        ROW_NUMBER() OVER (ORDER BY (catalog_profit + web_profit) DESC) AS rnk
    FROM sales_by_store
) ranked
WHERE rnk <= 100
ORDER BY rnk
LIMIT 100
