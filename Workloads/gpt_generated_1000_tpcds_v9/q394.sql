WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ca.ca_state,
        sm.sm_type,
        p.p_promo_name,
        CASE 
            WHEN p.p_channel_email = 'Y' THEN 'Email'
            WHEN p.p_channel_tv = 'Y' THEN 'TV'
            ELSE 'Other'
        END AS promo_channel,
        cc.cc_market_manager,
        wp.wp_image_count
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cc.cc_market_manager = 'Evan Saldana'
      AND sm.sm_type IN ('AIR', 'GROUND')
      AND wp.wp_image_count >= 3
),
aggregated AS (
    SELECT
        promo_channel,
        cs_bill_customer_sk,
        c_first_name,
        c_last_name,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        CASE WHEN SUM(cs_net_profit) > 0 THEN 'Profitable' ELSE 'Not Profitable' END AS profit_flag
    FROM sales_base
    WHERE promo_channel = 'Email'
    GROUP BY promo_channel, cs_bill_customer_sk, c_first_name, c_last_name
    HAVING SUM(cs_ext_sales_price) > 5000
    UNION ALL
    SELECT
        promo_channel,
        cs_bill_customer_sk,
        c_first_name,
        c_last_name,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        CASE WHEN SUM(cs_net_profit) > 0 THEN 'Profitable' ELSE 'Not Profitable' END AS profit_flag
    FROM sales_base
    WHERE promo_channel = 'TV'
    GROUP BY promo_channel, cs_bill_customer_sk, c_first_name, c_last_name
    HAVING SUM(cs_ext_sales_price) > 5000
)
SELECT
    promo_channel,
    cs_bill_customer_sk AS customer_sk,
    c_first_name,
    c_last_name,
    total_sales,
    total_profit,
    order_count,
    profit_flag,
    ROW_NUMBER() OVER (PARTITION BY promo_channel ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
