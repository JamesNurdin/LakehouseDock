WITH store_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'Store' AS sales_channel,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_quantity) AS avg_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
        MAX(d.d_date) AS latest_sale_date,
        COALESCE(s.s_city, 'UNKNOWN') AS location_desc,
        LOWER(COALESCE(s.s_city, 'UNKNOWN')) AS location_desc_lower,
        (SELECT COALESCE(SUM(sr.sr_refunded_cash), 0) FROM store_returns sr WHERE sr.sr_customer_sk = ss.ss_customer_sk) AS total_return_amount,
        CAST(NULL AS integer) AS is_call_center_open,
        CAST(NULL AS varchar) AS manager_name,
        CAST(NULL AS integer) AS is_home_page,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_promo_cost
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY ss.ss_customer_sk, c.c_first_name, c.c_last_name, d.d_year, s.s_city
),
catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'Catalog' AS sales_channel,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_quantity) AS avg_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        MAX(d.d_date) AS latest_sale_date,
        COALESCE(cc.cc_city, 'UNKNOWN') AS location_desc,
        LOWER(COALESCE(cc.cc_city, 'UNKNOWN')) AS location_desc_lower,
        (SELECT COALESCE(SUM(cr.cr_refunded_cash), 0) FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = cs.cs_bill_customer_sk) AS total_return_amount,
        CASE WHEN cc.cc_open_date_sk IS NOT NULL THEN 1 ELSE 0 END AS is_call_center_open,
        cc.cc_manager AS manager_name,
        CAST(NULL AS integer) AS is_home_page,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_promo_cost
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY cs.cs_bill_customer_sk, c.c_first_name, c.c_last_name, d.d_year, cc.cc_city, cc.cc_open_date_sk, cc.cc_manager
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'Web' AS sales_channel,
        d.d_year,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_quantity) AS avg_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS latest_sale_date,
        COALESCE(wp.wp_url, 'UNKNOWN') AS location_desc,
        LOWER(COALESCE(wp.wp_url, 'UNKNOWN')) AS location_desc_lower,
        (SELECT COALESCE(SUM(wr.wr_refunded_cash), 0) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = ws.ws_bill_customer_sk) AS total_return_amount,
        CAST(NULL AS integer) AS is_call_center_open,
        CAST(NULL AS varchar) AS manager_name,
        CASE WHEN wp.wp_type = 'home' THEN 1 ELSE 0 END AS is_home_page,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_promo_cost
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY ws.ws_bill_customer_sk, c.c_first_name, c.c_last_name, d.d_year, wp.wp_url, wp.wp_type
),
combined_sales AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
),
ranked_sales AS (
    SELECT
        customer_sk,
        customer_name,
        sales_channel,
        d_year,
        total_net_paid,
        total_net_profit,
        avg_quantity,
        order_count,
        latest_sale_date,
        location_desc,
        location_desc_lower,
        total_return_amount,
        is_call_center_open,
        manager_name,
        is_home_page,
        total_promo_cost,
        ROW_NUMBER() OVER (PARTITION BY sales_channel, d_year ORDER BY total_net_profit DESC) AS rn_year,
        RANK() OVER (PARTITION BY sales_channel ORDER BY total_net_profit DESC) AS rn_overall,
        SUM(total_net_profit) OVER (PARTITION BY sales_channel) AS channel_total_profit,
        SUM(total_net_profit) OVER () AS grand_total_profit
    FROM combined_sales
)
SELECT
    customer_sk,
    customer_name,
    sales_channel,
    d_year,
    total_net_paid,
    total_net_profit,
    ROUND(total_net_profit / NULLIF(channel_total_profit, 0) * 100, 2) AS profit_pct_of_channel,
    ROUND(total_net_profit / NULLIF(grand_total_profit, 0) * 100, 2) AS profit_pct_of_total,
    rn_year,
    rn_overall,
    location_desc,
    location_desc_lower,
    total_return_amount,
    CASE
        WHEN total_net_profit > 0 THEN 'Positive'
        WHEN total_net_profit = 0 THEN 'Zero'
        ELSE 'Negative'
    END AS profit_indicator,
    total_promo_cost,
    COALESCE(manager_name, 'N/A') AS manager,
    CASE
        WHEN is_call_center_open = 1 THEN 'CC_Open'
        WHEN is_call_center_open = 0 THEN 'CC_Closed'
        ELSE 'NA'
    END AS call_center_status,
    CASE
        WHEN is_home_page = 1 THEN 'HomePage'
        WHEN is_home_page = 0 THEN 'OtherPage'
        ELSE 'NA'
    END AS page_type
FROM ranked_sales
WHERE rn_year <= 5
ORDER BY sales_channel, d_year, rn_year
