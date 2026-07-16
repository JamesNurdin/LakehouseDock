WITH sales_agg AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_sold.d_year,
        d_sold.d_month_seq,
        cd_bill.cd_gender,
        cd_bill.cd_education_status,
        wp.wp_type,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(cd_bill.cd_purchase_estimate) AS avg_purchase_estimate
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    GROUP BY 
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_sold.d_year,
        d_sold.d_month_seq,
        cd_bill.cd_gender,
        cd_bill.cd_education_status,
        wp.wp_type
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    d_year,
    d_month_seq,
    cd_gender,
    cd_education_status,
    wp_type,
    order_cnt,
    total_quantity,
    total_net_profit,
    avg_purchase_estimate,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank_year
FROM sales_agg
ORDER BY d_year, profit_rank_year
