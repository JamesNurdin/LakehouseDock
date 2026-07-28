WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        i.i_category,
        i.i_brand,
        hd.hd_income_band_sk,
        ca.ca_state,
        td.t_hour,
        ss.ss_net_paid,
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        sr.sr_net_loss,
        wr.wr_net_loss,
        cc.cc_division,
        wp.wp_image_count,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ss.ss_net_paid DESC) AS rn_category
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND ca.ca_state = 'CA'
        AND i.i_category_id = 15
        AND cc.cc_division = 3
        AND hd.hd_income_band_sk BETWEEN 5 AND 10
        AND wp.wp_image_count > 3
        AND EXISTS (
            SELECT 1
            FROM catalog_page cp
            WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
              AND cp.cp_type = 'monthly'
        )
),
agg AS (
    SELECT
        i_category,
        COUNT(DISTINCT ss_ticket_number) AS orders,
        SUM(ss_net_paid) AS total_store_paid,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(sr_net_loss) AS total_store_return_loss,
        SUM(wr_net_loss) AS total_web_return_loss,
        AVG(CASE WHEN rn_category = 1 THEN ss_net_paid END) AS top_order_avg_paid
    FROM base
    GROUP BY i_category
    HAVING SUM(ss_net_paid) > 5000
)
SELECT
    i_category,
    orders,
    total_store_paid,
    total_catalog_sales,
    total_web_sales,
    (total_store_paid + total_catalog_sales + total_web_sales
        - COALESCE(total_store_return_loss, 0) - COALESCE(total_web_return_loss, 0)) AS net_contribution,
    CASE
        WHEN total_store_paid > 100000 THEN 'Very High'
        WHEN total_store_paid > 50000 THEN 'High'
        ELSE 'Normal'
    END AS store_sales_level,
    top_order_avg_paid
FROM agg
ORDER BY net_contribution DESC
LIMIT 100
