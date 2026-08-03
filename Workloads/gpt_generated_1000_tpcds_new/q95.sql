WITH ws_filt AS (
    SELECT
        ws_sold_date_sk,
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
    FROM web_sales
    WHERE ws_wholesale_cost > 20
      AND ws_ship_mode_sk IN (4, 9, 13)
      AND ws_quantity >= 2
      AND ws_ext_sales_price > 0
),
promo_filt AS (
    SELECT
        p_promo_sk,
        p_promo_id,
        p_promo_name,
        p_channel_email,
        p_channel_tv,
        p_discount_active,
        p_purpose
    FROM promotion
    WHERE p_channel_email = 'Y'
      AND p_channel_tv = 'N'
      AND p_discount_active = 'Y'
      AND p_purpose = 'C'
)
SELECT
    promo_filt.p_promo_id,
    promo_filt.p_promo_name,
    COALESCE(promo_filt.p_channel_email, 'N') AS channel_email,
    SUM(ws_filt.ws_ext_sales_price) AS total_sales,
    AVG(ws_filt.ws_net_profit) AS avg_profit,
    COUNT(ws_filt.ws_order_number) AS order_cnt,
    MIN(ws_filt.ws_wholesale_cost) AS min_wholesale,
    MAX(ws_filt.ws_list_price) AS max_list_price,
    CASE WHEN promo_filt.p_discount_active = 'Y'
         THEN SUM(ws_filt.ws_ext_sales_price) * 0.9
         ELSE SUM(ws_filt.ws_ext_sales_price)
    END AS adjusted_sales,
    ROW_NUMBER() OVER (
        PARTITION BY promo_filt.p_promo_id
        ORDER BY SUM(ws_filt.ws_ext_sales_price) DESC
    ) AS rn
FROM ws_filt
FULL OUTER JOIN promo_filt
    ON ws_filt.ws_promo_sk = promo_filt.p_promo_sk
GROUP BY
    promo_filt.p_promo_id,
    promo_filt.p_promo_name,
    COALESCE(promo_filt.p_channel_email, 'N'),
    promo_filt.p_discount_active
ORDER BY total_sales DESC
LIMIT 100
