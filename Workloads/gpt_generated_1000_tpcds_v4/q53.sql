WITH filtered_sales AS (
    SELECT ws_sold_date_sk,
           ws_sold_time_sk,
           ws_ship_date_sk,
           ws_item_sk,
           ws_bill_customer_sk,
           ws_bill_cdemo_sk,
           ws_bill_hdemo_sk,
           ws_bill_addr_sk,
           ws_ship_customer_sk,
           ws_ship_cdemo_sk,
           ws_ship_hdemo_sk,
           ws_ship_addr_sk,
           ws_web_page_sk,
           ws_web_site_sk,
           ws_ship_mode_sk,
           ws_warehouse_sk,
           ws_promo_sk,
           ws_order_number,
           ws_quantity,
           ws_wholesale_cost,
           ws_list_price,
           ws_sales_price,
           ws_ext_discount_amt,
           ws_ext_sales_price,
           ws_ext_wholesale_cost,
           ws_ext_list_price,
           ws_ext_tax,
           ws_coupon_amt,
           ws_ext_ship_cost,
           ws_net_paid,
           ws_net_paid_inc_tax,
           ws_net_paid_inc_ship,
           ws_net_paid_inc_ship_tax,
           ws_net_profit
    FROM tpcds.web_sales
    WHERE ws_ext_list_price > 1000
      AND ws_quantity >= 2
      AND ws_net_paid_inc_ship_tax BETWEEN 200 AND 4000
      AND ws_ship_customer_sk IS NOT NULL
),
filtered_page AS (
    SELECT wp_web_page_sk,
           wp_web_page_id,
           wp_rec_start_date,
           wp_rec_end_date,
           wp_creation_date_sk,
           wp_access_date_sk,
           wp_autogen_flag,
           wp_customer_sk,
           wp_url,
           wp_type,
           wp_char_count,
           wp_link_count,
           wp_image_count,
           wp_max_ad_count
    FROM tpcds.web_page
    WHERE wp_rec_start_date >= DATE '1999-01-01'
      AND wp_type IN ('home', 'product', 'search')
      AND wp_char_count > 1000
      AND wp_link_count >= 5
)
SELECT
    wp.wp_web_page_id,
    wp.wp_type,
    ws.ws_order_number,
    ws.ws_ext_list_price,
    ws.ws_net_paid_inc_ship_tax,
    CASE
        WHEN ws.ws_ext_discount_amt > 1000 THEN 'High Discount'
        WHEN ws.ws_ext_discount_amt > 0  THEN 'Low Discount'
        ELSE 'No Discount'
    END AS discount_category,
    RANK() OVER (PARTITION BY wp.wp_type ORDER BY ws.ws_net_paid_inc_ship_tax DESC) AS type_rank,
    SUM(ws.ws_ext_sales_price) OVER (PARTITION BY wp.wp_web_page_id) AS total_sales_per_page
FROM filtered_page wp
JOIN filtered_sales ws
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_rec_end_date > DATE '2000-12-31'
ORDER BY wp.wp_type, type_rank
LIMIT 100
