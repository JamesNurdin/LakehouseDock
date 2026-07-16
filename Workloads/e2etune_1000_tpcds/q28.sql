WITH base AS (
    SELECT
        s.web_name AS web_site_name,
        i.i_category AS item_category,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'High Risk'
      AND cd.cd_education_status = 'College'
      AND p.p_discount_active = 'Y'
      AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY s.web_name, i.i_category
    HAVING SUM(ws.ws_net_profit) > 0
)
SELECT
    web_site_name,
    item_category,
    unique_customers,
    total_net_profit,
    total_sales,
    avg_discount,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM base
ORDER BY total_net_profit DESC
LIMIT 50
