WITH joined_sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_color,
        i.i_rec_start_date,
        t.t_hour,
        cd.cd_credit_rating,
        ca.ca_state,
        ss.ss_quantity AS store_quantity,
        ss.ss_net_profit AS store_net_profit,
        ws.ws_quantity AS web_quantity,
        ws.ws_net_profit AS web_net_profit,
        wp.wp_max_ad_count
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        i.i_color IN ('red', 'lime')
        AND i.i_rec_start_date >= DATE '1999-01-01'
        AND t.t_hour BETWEEN 9 AND 17
        AND cd.cd_credit_rating = 'Good'
        AND wp.wp_max_ad_count >= 2
        AND ss.ss_quantity > 1
        AND ws.ws_quantity > 0
        AND EXISTS (
            SELECT 1
            FROM customer_address ca2
            WHERE ca2.ca_address_sk = ws.ws_bill_addr_sk
              AND ca2.ca_state = 'CA'
        )
),
per_item AS (
    SELECT
        i_item_id,
        i_product_name,
        SUM(store_net_profit + web_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM joined_sales
    GROUP BY i_item_id, i_product_name
),
avg_profit AS (
    SELECT AVG(total_profit) AS avg_total_profit
    FROM per_item
)
SELECT
    pi.i_item_id,
    pi.i_product_name,
    pi.total_profit,
    pi.sales_cnt,
    ap.avg_total_profit
FROM per_item pi
CROSS JOIN avg_profit ap
WHERE pi.total_profit > ap.avg_total_profit
ORDER BY pi.total_profit DESC
LIMIT 100
