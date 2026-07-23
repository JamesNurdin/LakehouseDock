WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        ws.ws_sold_date_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        p.p_discount_active,
        p.p_promo_name,
        wp.wp_url,
        wr.wr_return_amt
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
    WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
      AND wp.wp_url LIKE '%promo%'
)
SELECT
    cd_gender,
    CASE WHEN p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    regexp_extract(c_email_address, '@(.*)$', 1) AS email_domain,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    SUM(COALESCE(wr_return_amt, 0)) AS total_return_amount,
    SUM(ws_ext_sales_price) - SUM(COALESCE(wr_return_amt, 0)) AS net_sales_after_returns,
    MAX(SUBSTRING(wp_url, 1, 30)) AS sample_url
FROM sales_data
GROUP BY
    cd_gender,
    CASE WHEN p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END,
    regexp_extract(c_email_address, '@(.*)$', 1)
HAVING SUM(ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
