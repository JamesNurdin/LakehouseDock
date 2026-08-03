WITH
    filtered_items AS (
        SELECT i_item_sk,
               i_product_name,
               i_brand,
               i_category,
               i_color,
               i_item_desc
        FROM   item
        WHERE  regexp_like(i_product_name, '(?i)Pro')
    ),
    promo_items AS (
        SELECT DISTINCT p.p_item_sk AS i_item_sk
        FROM   promotion p
        JOIN   item i ON p.p_item_sk = i.i_item_sk
        WHERE  regexp_like(p.p_promo_name, '^Summer')
    ),
    eligible_items AS (
        SELECT i_item_sk FROM filtered_items
        INTERSECT
        SELECT i_item_sk FROM promo_items
    ),
    web_sales_agg AS (
        SELECT ws.ws_web_site_sk,
               wep.web_company_name,
               d.d_year,
               ws.ws_sold_date_sk,
               SUM(ws.ws_net_paid)                          AS total_net_paid,
               COUNT(DISTINCT ws.ws_bill_customer_sk)       AS distinct_customers,
               sm.sm_code,
               sm.sm_contract
        FROM   web_sales ws
        JOIN   eligible_items ei ON ws.ws_item_sk = ei.i_item_sk
        JOIN   date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN   ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN   web_site wep ON ws.ws_web_site_sk = wep.web_site_sk
        WHERE  sm.sm_code LIKE 'A%'
          AND regexp_like(sm.sm_contract, '^[A-Z]{3}[0-9]$')
        GROUP BY ws.ws_web_site_sk,
                 wep.web_company_name,
                 d.d_year,
                 ws.ws_sold_date_sk,
                 sm.sm_code,
                 sm.sm_contract
    ),
    ranked_sales AS (
        SELECT web_company_name,
               d_year,
               total_net_paid,
               distinct_customers,
               sm_code,
               sm_contract,
               ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS rnk,
               CONCAT(substr(sm_code, 1, 1), '-', substr(sm_contract, 1, 3)) AS code_prefix
        FROM   web_sales_agg
    )
SELECT DISTINCT
    web_company_name,
    d_year,
    total_net_paid,
    distinct_customers,
    sm_code,
    sm_contract,
    code_prefix,
    rnk
FROM   ranked_sales
WHERE  rnk <= 3
ORDER BY d_year,
         rnk
LIMIT 100
