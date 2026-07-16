WITH filtered_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
),
catalog AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk,
           cs.cs_order_number AS order_number,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_ext_sales_price AS ext_sales,
           cs.cs_ext_discount_amt AS discount,
           cs.cs_net_profit AS net_profit,
           cs.cs_item_sk AS item_sk,
           cs.cs_promo_sk AS promo_sk,
           'Catalog' AS channel
    FROM catalog_sales cs
    JOIN filtered_dates fd ON cs.cs_sold_date_sk = fd.d_date_sk
),
store AS (
    SELECT ss.ss_customer_sk AS cust_sk,
           ss.ss_ticket_number AS order_number,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_ext_sales_price AS ext_sales,
           ss.ss_ext_discount_amt AS discount,
           ss.ss_net_profit AS net_profit,
           ss.ss_item_sk AS item_sk,
           ss.ss_promo_sk AS promo_sk,
           'Store' AS channel
    FROM store_sales ss
    JOIN filtered_dates fd ON ss.ss_sold_date_sk = fd.d_date_sk
),
web AS (
    SELECT ws.ws_bill_customer_sk AS cust_sk,
           ws.ws_order_number AS order_number,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_ext_sales_price AS ext_sales,
           ws.ws_ext_discount_amt AS discount,
           ws.ws_net_profit AS net_profit,
           ws.ws_item_sk AS item_sk,
           ws.ws_promo_sk AS promo_sk,
           'Web' AS channel
    FROM web_sales ws
    JOIN filtered_dates fd ON ws.ws_sold_date_sk = fd.d_date_sk
),
base_sales AS (
    SELECT * FROM catalog
    UNION ALL
    SELECT * FROM store
    UNION ALL
    SELECT * FROM web
),
sales_enriched AS (
    SELECT
        bs.cust_sk,
        bs.order_number,
        bs.date_sk,
        bs.ext_sales,
        bs.discount,
        bs.net_profit,
        bs.item_sk,
        bs.promo_sk,
        bs.channel,
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        p.p_discount_active
    FROM base_sales bs
    LEFT JOIN item i ON bs.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON bs.promo_sk = p.p_promo_sk
),
sales_window AS (
    SELECT
        se.*,
        ROW_NUMBER() OVER (PARTITION BY channel ORDER BY net_profit DESC) AS channel_rank,
        SUM(net_profit) OVER (PARTITION BY cust_sk ORDER BY date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
    FROM sales_enriched se
),
customer_enriched AS (
    SELECT
        c.c_customer_sk,
        CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
        COALESCE(c.c_preferred_cust_flag, 'N') AS pref_flag,
        c.c_email_address,
        ca.ca_state,
        ca.ca_country,
        c.c_birth_year,
        c.c_birth_month,
        c.c_birth_day
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
customer_total_profit AS (
    SELECT cust_sk, SUM(net_profit) AS total_profit
    FROM sales_window
    GROUP BY cust_sk
),
profit_threshold AS (
    SELECT AVG(total_profit) * 1.5 AS min_profit
    FROM customer_total_profit
),
customer_agg AS (
    SELECT
        ce.c_customer_sk,
        ce.full_name,
        CASE 
            WHEN ce.c_email_address IS NULL THEN 'UNKNOWN'
            ELSE regexp_replace(ce.c_email_address, '^(.{3}).*@', '\\1***@')
        END AS masked_email,
        ce.ca_state,
        ce.ca_country,
        CASE 
            WHEN ce.c_birth_year IS NULL THEN NULL
            ELSE CONCAT(CAST(ce.c_birth_year AS VARCHAR), '-', LPAD(CAST(ce.c_birth_month AS VARCHAR),2,'0'), '-', LPAD(CAST(ce.c_birth_day AS VARCHAR),2,'0'))
        END AS birth_date,
        SUM(sw.ext_sales) AS total_sales,
        SUM(sw.net_profit) AS total_net_profit,
        SUM(sw.discount) AS total_discount,
        CASE WHEN SUM(sw.ext_sales) = 0 THEN 0 ELSE SUM(sw.net_profit) / SUM(sw.ext_sales) END AS profit_margin,
        COUNT(DISTINCT sw.order_number) AS distinct_orders,
        AVG(CASE WHEN sw.ext_sales > 0 THEN sw.discount / sw.ext_sales END) AS avg_discount_rate,
        MAX(CASE WHEN sw.channel = 'Store' THEN sw.ext_sales END) AS max_store_sale,
        MIN(CASE WHEN sw.channel = 'Web' THEN sw.ext_sales END) AS min_web_sale,
        COUNT(*) FILTER (WHERE sw.p_discount_active = 'Y') AS active_promotions_used,
        COUNT(DISTINCT sw.i_brand) AS distinct_brands,
        (SELECT MAX(swp3.net_profit) FROM sales_window swp3 WHERE swp3.cust_sk = ce.c_customer_sk) AS max_single_sale_profit,
        (SELECT AVG(swp2.net_profit) FROM sales_window swp2 WHERE swp2.cust_sk = ce.c_customer_sk) AS avg_item_profit,
        (SELECT swp4.p_promo_name FROM sales_window swp4 WHERE swp4.cust_sk = ce.c_customer_sk AND swp4.p_promo_name IS NOT NULL ORDER BY swp4.net_profit DESC LIMIT 1) AS top_promo_name
    FROM sales_window sw
    JOIN customer_enriched ce ON sw.cust_sk = ce.c_customer_sk
    WHERE (ce.pref_flag = 'Y' OR ce.c_email_address LIKE '%@example.com')
      AND (sw.p_promo_name IS NULL OR sw.p_promo_name NOT LIKE '%TEST%')
      AND sw.ext_sales IS NOT NULL
      AND sw.net_profit IS NOT NULL
      AND sw.channel_rank <= 5
    GROUP BY
        ce.c_customer_sk,
        ce.full_name,
        ce.c_email_address,
        ce.ca_state,
        ce.ca_country,
        ce.c_birth_year,
        ce.c_birth_month,
        ce.c_birth_day,
        CASE 
            WHEN ce.c_email_address IS NULL THEN 'UNKNOWN'
            ELSE regexp_replace(ce.c_email_address, '^(.{3}).*@', '\\1***@')
        END,
        CASE 
            WHEN ce.c_birth_year IS NULL THEN NULL
            ELSE CONCAT(CAST(ce.c_birth_year AS VARCHAR), '-', LPAD(CAST(ce.c_birth_month AS VARCHAR),2,'0'), '-', LPAD(CAST(ce.c_birth_day AS VARCHAR),2,'0'))
        END
    HAVING SUM(sw.net_profit) > (SELECT min_profit FROM profit_threshold)
)
SELECT
    ca.*,
    RANK() OVER (ORDER BY ca.total_net_profit DESC) AS profit_rank
FROM customer_agg ca
ORDER BY ca.total_net_profit DESC
LIMIT 10
