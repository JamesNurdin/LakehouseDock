WITH cs_promo_full AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_addr_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_wholesale_cost,
        cs.cs_list_price,
        cs.cs_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_ext_sales_price,
        cs.cs_ext_wholesale_cost,
        cs.cs_ext_list_price,
        cs.cs_ext_tax,
        cs.cs_coupon_amt,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_paid_inc_ship,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_net_profit,
        p.p_promo_id,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_item_sk,
        p.p_cost,
        p.p_response_target,
        p.p_promo_name,
        p.p_channel_dmail,
        p.p_channel_email,
        p.p_channel_catalog,
        p.p_channel_tv,
        p.p_channel_radio,
        p.p_channel_press,
        p.p_channel_event,
        p.p_channel_demo,
        p.p_channel_details,
        p.p_purpose,
        p.p_discount_active
    FROM catalog_sales cs
    FULL OUTER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
)
SELECT
    store.s_state,
    cs_promo_full.p_purpose,
    COUNT(DISTINCT cs_promo_full.cs_order_number) AS order_count,
    SUM(cs_promo_full.cs_ext_sales_price) AS total_sales,
    AVG(web_sales.ws_net_paid_inc_ship) AS avg_web_paid,
    SUM(CASE WHEN reason.r_reason_desc LIKE '%service%' THEN store_returns.sr_return_amt ELSE 0 END) AS service_return_total,
    MAX(cs_promo_full.cs_net_paid) AS max_catalog_net_paid
FROM cs_promo_full
JOIN customer
    ON cs_promo_full.cs_bill_customer_sk = customer.c_customer_sk
JOIN customer_demographics
    ON cs_promo_full.cs_bill_cdemo_sk = customer_demographics.cd_demo_sk
JOIN customer_address
    ON cs_promo_full.cs_bill_addr_sk = customer_address.ca_address_sk
JOIN warehouse
    ON cs_promo_full.cs_warehouse_sk = warehouse.w_warehouse_sk
JOIN inventory
    ON inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
JOIN store_returns
    ON store_returns.sr_customer_sk = customer.c_customer_sk
JOIN store
    ON store_returns.sr_store_sk = store.s_store_sk
JOIN reason
    ON store_returns.sr_reason_sk = reason.r_reason_sk
JOIN web_sales
    ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
JOIN web_page
    ON web_sales.ws_web_page_sk = web_page.wp_web_page_sk
JOIN web_site
    ON web_sales.ws_web_site_sk = web_site.web_site_sk
WHERE cs_promo_full.cs_quantity > 5
  AND cs_promo_full.cs_ext_tax > 100
  AND cs_promo_full.cs_sold_date_sk BETWEEN 2450000 AND 2450100
  AND cs_promo_full.p_discount_active = 'Y'
  AND store.s_state = 'CA'
  AND reason.r_reason_desc NOT LIKE '%unauthorized%'
  AND cs_promo_full.cs_net_paid > (SELECT MAX(cs2.cs_net_paid) FROM catalog_sales cs2) - 1000
  AND cs_promo_full.cs_item_sk IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 0)
GROUP BY store.s_state, cs_promo_full.p_purpose
ORDER BY total_sales DESC
LIMIT 100
