WITH site_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_promo_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ext_list_price,
        ws.ws_list_price,
        ws.ws_ext_discount_amt,
        s.web_site_id,
        s.web_company_name,
        s.web_city,
        s.web_state,
        s.web_tax_percentage,
        -- extract the first three characters of the company name
        regexp_extract(s.web_company_name, '^(.{3})', 1) AS company_prefix,
        -- concatenate city and state for display
        CONCAT(s.web_city, ', ', s.web_state) AS city_state,
        -- flag if the company name contains the letter "a" (case‑insensitive)
        CASE WHEN regexp_like(s.web_company_name, '[aA]') THEN true ELSE false END AS has_letter_a
    FROM
        web_sales ws
        JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE
        s.web_tax_percentage > 0.00
        AND s.web_city LIKE 'L%'
        AND regexp_like(s.web_company_name, '^[a-zA-Z]{4,}$')
),
aggregated AS (
    SELECT
        ss.web_site_id,
        ss.web_company_name,
        ss.city_state,
        ss.company_prefix,
        COUNT(DISTINCT ss.ws_order_number) AS order_count,
        SUM(ss.ws_net_profit) AS total_net_profit,
        AVG(ss.ws_net_profit) AS avg_net_profit,
        SUM(ss.ws_ext_sales_price) AS total_sales,
        SUM(ss.ws_net_profit) / SUM(ss.ws_ext_sales_price) AS profit_margin
    FROM
        site_sales ss
    GROUP BY
        ss.web_site_id,
        ss.web_company_name,
        ss.city_state,
        ss.company_prefix
    HAVING
        SUM(ss.ws_net_profit) > 1000
)
SELECT
    a.web_site_id,
    a.web_company_name,
    a.city_state,
    a.company_prefix,
    a.order_count,
    a.total_net_profit,
    a.avg_net_profit,
    a.total_sales,
    a.profit_margin,
    ROW_NUMBER() OVER (ORDER BY a.total_net_profit DESC) AS profit_rank,
    SUM(a.total_net_profit) OVER () AS total_profit_all_sites
FROM
    aggregated a
ORDER BY
    a.total_net_profit DESC
LIMIT 100
