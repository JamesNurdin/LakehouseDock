WITH billed_sales AS (
    SELECT
        ca.ca_state AS state,
        cp.cp_department AS department,
        p.p_channel_email AS channel_flag,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        'BILL' AS address_type
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'N'
      AND cp.cp_start_date_sk BETWEEN 2450965 AND 2451271
      AND ca.ca_state IN ('CA', 'TX')
    GROUP BY GROUPING SETS (
        (ca.ca_state, cp.cp_department, p.p_channel_email),
        (ca.ca_state, cp.cp_department),
        (ca.ca_state),
        ()
    )
),
shipped_sales AS (
    SELECT
        ca.ca_state AS state,
        cp.cp_department AS department,
        p.p_channel_demo AS channel_flag,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        'SHIP' AS address_type
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_demo = 'N'
      AND cp.cp_end_date_sk BETWEEN 2451115 AND 2451271
      AND ca.ca_state IN ('NY', 'FL')
    GROUP BY GROUPING SETS (
        (ca.ca_state, cp.cp_department, p.p_channel_demo),
        (ca.ca_state, cp.cp_department),
        (ca.ca_state),
        ()
    )
)
SELECT
    state,
    department,
    channel_flag,
    total_sales,
    total_profit,
    order_cnt,
    address_type
FROM billed_sales
UNION ALL
SELECT
    state,
    department,
    channel_flag,
    total_sales,
    total_profit,
    order_cnt,
    address_type
FROM shipped_sales
ORDER BY state ASC NULLS LAST, department ASC NULLS LAST, address_type
