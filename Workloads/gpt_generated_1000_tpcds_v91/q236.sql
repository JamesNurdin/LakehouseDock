WITH sales_ids AS (
    SELECT ss_ticket_number AS ticket_number
    FROM store_sales
),
returned_ids AS (
    SELECT sr_ticket_number AS ticket_number
    FROM store_returns
),
sales_no_returns AS (
    SELECT ticket_number FROM sales_ids
    EXCEPT
    SELECT ticket_number FROM returned_ids
),
joined_data AS (
    SELECT
        d.d_date AS d_date,
        i.i_item_id AS i_item_id,
        i.i_brand AS i_brand,
        cd.cd_gender AS gender,
        w.w_warehouse_name AS w_warehouse_name,
        ss.ss_ext_sales_price AS store_sales_amount,
        ws.ws_ext_sales_price AS web_sales_amount,
        ss.ss_net_profit AS store_net_profit,
        ca.ca_address_sk AS ca_address_sk,
        ss.ss_customer_sk AS ss_customer_sk
    FROM sales_no_returns snr
    JOIN store_sales ss
        ON ss.ss_ticket_number = snr.ticket_number
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 1998
      AND t.t_meal_time = 'dinner'
      AND i.i_brand = 'Brand#45'
      AND w.w_state = 'CA'
)
SELECT
    d_date,
    i_item_id,
    i_brand,
    gender,
    w_warehouse_name,
    SUM(store_sales_amount) AS total_store_sales,
    SUM(web_sales_amount) AS total_web_sales,
    SUM(store_sales_amount) + SUM(web_sales_amount) AS total_combined_sales,
    AVG(store_net_profit) AS avg_store_profit,
    COUNT(DISTINCT ca_address_sk) AS distinct_customer_addresses,
    COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
    COUNT(*) AS transaction_count
FROM joined_data
GROUP BY d_date, i_item_id, i_brand, gender, w_warehouse_name
ORDER BY total_combined_sales DESC
LIMIT 100
