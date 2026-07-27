WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        ca.ca_state,
        cd.cd_gender,
        sm.sm_type,
        p.p_promo_name,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT cs.cs_order_number) AS cnt_catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS cnt_web_orders,
        CASE
            WHEN SUM(cs.cs_net_paid) > SUM(ws.ws_net_paid) THEN 'Catalog Higher'
            ELSE 'Web Higher'
        END AS sales_channel_preference
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        ca.ca_state = 'CA'
        AND cd.cd_purchase_estimate >= 6000
        AND sm.sm_type = 'EXPRESS'
        AND p.p_discount_active = 'Y'
        AND cs.cs_quantity > 2
        AND ws.ws_quantity > 2
        AND wp.wp_type = 'HOME'
    GROUP BY ROLLUP (c.c_customer_id, ca.ca_state, cd.cd_gender, sm.sm_type, p.p_promo_name)
)
SELECT
    c_customer_id,
    ca_state,
    cd_gender,
    sm_type,
    p_promo_name,
    total_catalog_sales,
    total_web_sales,
    cnt_catalog_orders,
    cnt_web_orders,
    sales_channel_preference,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY (total_catalog_sales + total_web_sales) DESC) AS state_rank,
    RANK() OVER (ORDER BY (total_catalog_sales + total_web_sales) DESC) AS overall_rank
FROM sales_agg
WHERE sales_channel_preference IS NOT NULL
ORDER BY overall_rank
LIMIT 100
