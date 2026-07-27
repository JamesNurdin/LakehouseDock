WITH base_agg AS (
    SELECT
        i.i_brand,
        sm.sm_code,
        sm.sm_contract,
        i.i_units,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_returns,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM
        tpcds.web_sales ws
        INNER JOIN tpcds.item i
            ON ws.ws_item_sk = i.i_item_sk
        INNER JOIN tpcds.ship_mode sm
            ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT OUTER JOIN tpcds.web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT OUTER JOIN tpcds.web_returns wr
            ON ws.ws_order_number = wr.wr_order_number
            AND ws.ws_item_sk = wr.wr_item_sk
    WHERE
        sm.sm_code = 'AIR'                         -- predicate 1
        AND sm.sm_contract LIKE 'A%'               -- predicate 2
        AND i.i_brand = 'importoamalg #1'          -- predicate 3
        AND i.i_units = 'Box'                      -- predicate 4
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000  -- predicate 5
        AND i.i_category_id IN (1, 2, 3)           -- predicate 6
    GROUP BY
        i.i_brand,
        sm.sm_code,
        sm.sm_contract,
        i.i_units
),
brand_stats AS (
    SELECT
        i_brand,
        AVG(total_sales) AS avg_sales,
        AVG(total_returns) AS avg_returns,
        AVG(total_sales - total_returns) AS avg_net_sales
    FROM
        base_agg
    GROUP BY
        i_brand
    HAVING
        AVG(total_sales - total_returns) > 5000
)
SELECT
    i_brand,
    avg_sales,
    avg_returns,
    avg_net_sales
FROM
    brand_stats
ORDER BY
    avg_net_sales DESC
LIMIT 100
