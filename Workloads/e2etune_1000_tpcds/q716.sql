WITH store_agg AS (
    SELECT
        i.i_category AS category,
        cd.cd_gender AS gender,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_ext_list_price) AS store_list,
        SUM(ss.ss_quantity) AS store_quantity,
        AVG(CASE WHEN ss.ss_ext_list_price > 0 THEN (ss.ss_ext_list_price - ss.ss_ext_sales_price) / ss.ss_ext_list_price END) AS store_avg_discount
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450900 AND 2451100
      AND i.i_category = 'Sports'
      AND cd.cd_gender = 'M'
      AND cd.cd_education_status = 'College'
    GROUP BY i.i_category, cd.cd_gender
),
web_agg AS (
    SELECT
        i.i_category AS category,
        cd_bill.cd_gender AS gender,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_ext_list_price) AS web_list,
        SUM(ws.ws_quantity) AS web_quantity,
        AVG(CASE WHEN ws.ws_ext_list_price > 0 THEN (ws.ws_ext_list_price - ws.ws_ext_sales_price) / ws.ws_ext_list_price END) AS web_avg_discount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450900 AND 2451100
      AND i.i_category = 'Sports'
      AND cd_bill.cd_gender = 'M'
      AND cd_bill.cd_education_status = 'College'
      AND sm.sm_type = 'AIR'
    GROUP BY i.i_category, cd_bill.cd_gender
)
SELECT
    COALESCE(sa.category, wa.category) AS category,
    COALESCE(sa.gender, wa.gender) AS gender,
    COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) AS total_net_profit,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    (COALESCE(sa.store_sales, 0) + COALESCE(wa.web_sales, 0)) AS total_sales,
    (COALESCE(sa.store_list, 0) + COALESCE(wa.web_list, 0)) AS total_list_price,
    (COALESCE(sa.store_avg_discount, 0) * COALESCE(sa.store_sales, 0) + COALESCE(wa.web_avg_discount, 0) * COALESCE(wa.web_sales, 0))
        / NULLIF((COALESCE(sa.store_sales, 0) + COALESCE(wa.web_sales, 0)), 0) AS weighted_avg_discount
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.category = wa.category AND sa.gender = wa.gender
ORDER BY total_net_profit DESC
LIMIT 10
