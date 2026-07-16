WITH
recent_catalog_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        d.d_date AS sale_date,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_quantity AS quantity,
        cs.cs_sales_price AS sales_price,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel,
        CAST(cs.cs_call_center_sk AS VARCHAR) AS sk_str
    FROM catalog_sales cs
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002 AND cs.cs_quantity > 0
),
recent_store_sales AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        d.d_date AS sale_date,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_quantity AS quantity,
        ss.ss_sales_price AS sales_price,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        'store' AS channel,
        CAST(ss.ss_store_sk AS VARCHAR) AS sk_str
    FROM store_sales ss
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002 AND ss.ss_quantity > 0
),
recent_web_sales AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        d.d_date AS sale_date,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_quantity AS quantity,
        ws.ws_sales_price AS sales_price,
        ws.ws_ext_sales_price AS ext_sales_price,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        'web' AS channel,
        CAST(ws.ws_web_page_sk AS VARCHAR) AS sk_str
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002 AND ws.ws_quantity > 0
),
combined_sales AS (
    SELECT * FROM recent_catalog_sales
    UNION ALL
    SELECT * FROM recent_store_sales
    UNION ALL
    SELECT * FROM recent_web_sales
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS full_name,
        c.c_preferred_cust_flag,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_gmt_offset,
        COALESCE(c.c_birth_year, 1900) AS birth_year,
        CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END AS pref_flag_int
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_with_customer AS (
    SELECT
        cs.date_sk,
        cs.sale_date,
        cs.item_sk,
        cs.customer_sk,
        cs.quantity,
        cs.sales_price,
        cs.ext_sales_price,
        cs.net_paid,
        cs.net_profit,
        cs.channel,
        cs.sk_str,
        ci.full_name,
        ci.c_preferred_cust_flag,
        ci.pref_flag_int,
        COALESCE(ci.ca_city, 'UNKNOWN') AS city,
        COALESCE(ci.ca_state, 'UNKNOWN') AS state,
        COALESCE(ci.ca_country, 'UNKNOWN') AS country,
        CASE WHEN cs.sale_date IS NOT NULL THEN EXTRACT(YEAR FROM cs.sale_date) - ci.birth_year ELSE NULL END AS age_at_sale,
        CASE WHEN cs.ext_sales_price IS NOT NULL AND cs.ext_sales_price <> 0 THEN cs.net_profit / NULLIF(cs.ext_sales_price, 0) ELSE NULL END AS profit_margin,
        CONCAT('CUST_', COALESCE(CAST(cs.customer_sk AS VARCHAR), 'NULL'), '_', cs.channel) AS pseudo_id
    FROM combined_sales cs
    LEFT JOIN customer_info ci ON cs.customer_sk = ci.c_customer_sk
),
ranked_sales AS (
    SELECT
        swc.*,
        ROW_NUMBER() OVER (PARTITION BY swc.pseudo_id ORDER BY swc.sale_date DESC NULLS LAST) AS rn,
        SUM(swc.ext_sales_price) OVER (PARTITION BY swc.pseudo_id) AS total_sales_per_customer,
        COUNT(*) OVER (PARTITION BY swc.channel) AS sales_count_per_channel
    FROM sales_with_customer swc
),
top5_sales AS (
    SELECT *
    FROM ranked_sales
    WHERE rn <= 5
),
returners AS (
    SELECT DISTINCT cr.cr_returning_customer_sk AS customer_sk FROM catalog_returns cr
    UNION
    SELECT DISTINCT sr.sr_customer_sk FROM store_returns sr
    UNION
    SELECT DISTINCT wr.wr_returning_customer_sk FROM web_returns wr
),
frequent_return_reasons AS (
    SELECT
        r.r_reason_desc,
        COUNT(*) AS cnt
    FROM (
        SELECT cr.cr_reason_sk AS reason_sk FROM catalog_returns cr
        UNION ALL
        SELECT sr.sr_reason_sk FROM store_returns sr
        UNION ALL
        SELECT wr.wr_reason_sk FROM web_returns wr
    ) all_reasons
    JOIN reason r ON all_reasons.reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
    ORDER BY cnt DESC
    LIMIT 5
),
boundary_cases AS (
    SELECT
        c.c_customer_sk,
        COALESCE(CAST(c.c_current_addr_sk AS VARCHAR), 'NULL') AS addr_sk_string,
        CASE
            WHEN c.c_current_addr_sk IS NULL THEN 'MISSING_ADDRESS'
            WHEN c.c_current_addr_sk = 0 THEN 'ZERO_ADDRESS'
            ELSE 'VALID_ADDRESS'
        END AS address_status,
        REGEXP_REPLACE(COALESCE(c.c_login, ''), '[^a-zA-Z0-9]', '') AS alphanum_login,
        LENGTH(COALESCE(c.c_email_address, '')) AS email_len,
        CASE
            WHEN c.c_birth_year IS NULL OR c.c_birth_month IS NULL THEN NULL
            ELSE c.c_birth_year / NULLIF(NULLIF(c.c_birth_month, 0), 0)
        END AS birth_year_div_month
    FROM customer c
    WHERE c.c_customer_id IS NOT NULL
),
final AS (
    SELECT
        ts.pseudo_id,
        ts.full_name,
        ts.channel,
        ts.sale_date,
        ts.quantity,
        ts.sales_price AS unit_price,
        ts.ext_sales_price AS total_price,
        ts.profit_margin,
        ts.total_sales_per_customer,
        ts.sales_count_per_channel,
        CASE WHEN rr.customer_sk IS NOT NULL THEN 'YES' ELSE 'NO' END AS has_returned_before,
        COALESCE(bc.address_status, 'UNKNOWN') AS address_status,
        bc.alphanum_login,
        bc.email_len,
        bc.birth_year_div_month,
        fr.r_reason_desc AS top_reason_for_returns
    FROM top5_sales ts
    LEFT JOIN returners rr ON ts.customer_sk = rr.customer_sk
    LEFT JOIN boundary_cases bc ON ts.customer_sk = bc.c_customer_sk
    LEFT JOIN (SELECT r_reason_desc FROM frequent_return_reasons LIMIT 1) fr ON TRUE
    WHERE ts.profit_margin IS NOT NULL
)
SELECT *
FROM final
ORDER BY profit_margin DESC NULLS LAST
LIMIT 100
