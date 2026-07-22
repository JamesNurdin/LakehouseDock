WITH cs AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS cs_sales,
        SUM(cs.cs_net_profit) AS cs_profit,
        MAX(cs.cs_catalog_page_sk) AS cs_catalog_page_sk,
        MAX(cs.cs_promo_sk) AS cs_promo_sk,
        MAX(cs.cs_bill_customer_sk) AS cs_bill_customer_sk,
        MAX(cs.cs_bill_cdemo_sk) AS cs_bill_cdemo_sk,
        MAX(cs.cs_bill_addr_sk) AS cs_bill_addr_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs.cs_item_sk
),
ws AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS ws_sales,
        SUM(ws.ws_net_profit) AS ws_profit,
        MAX(ws.ws_web_page_sk) AS ws_web_page_sk,
        MAX(ws.ws_web_site_sk) AS ws_web_site_sk,
        MAX(ws.ws_promo_sk) AS ws_promo_sk,
        MAX(ws.ws_bill_customer_sk) AS ws_bill_customer_sk,
        MAX(ws.ws_bill_cdemo_sk) AS ws_bill_cdemo_sk,
        MAX(ws.ws_bill_addr_sk) AS ws_bill_addr_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_item_sk
),
sr AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_amt) AS sr_return_amount,
        SUM(sr.sr_net_loss) AS sr_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    COALESCE(cs.cs_sales, 0) AS catalog_sales,
    COALESCE(ws.ws_sales, 0) AS web_sales,
    COALESCE(sr.sr_return_amount, 0) AS total_returns,
    (COALESCE(cs.cs_profit, 0) + COALESCE(ws.ws_profit, 0) - COALESCE(sr.sr_return_loss, 0)) AS net_profit,
    p_cs.p_promo_name AS catalog_promo,
    p_ws.p_promo_name AS web_promo,
    cp.cp_department,
    wp.wp_url,
    wsit.web_name,
    c.c_first_name,
    ca.ca_city,
    cd.cd_gender,
    ROW_NUMBER() OVER (
        ORDER BY (COALESCE(cs.cs_profit, 0) + COALESCE(ws.ws_profit, 0) - COALESCE(sr.sr_return_loss, 0)) DESC
    ) AS profit_rank
FROM item i
LEFT JOIN cs ON i.i_item_sk = cs.cs_item_sk
LEFT JOIN ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN sr ON i.i_item_sk = sr.sr_item_sk
LEFT JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE i.i_category = 'Sports'
  AND p_cs.p_discount_active = 'Y'
  AND cp.cp_department = 'DEPARTMENT'
ORDER BY net_profit DESC
LIMIT 100
