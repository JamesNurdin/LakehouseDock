WITH catalog_agg AS (
    SELECT
        p.p_promo_name AS promo_name,
        ca.ca_state AS state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_quantity > 2
      AND cs.cs_ext_sales_price > 150
      AND p.p_discount_active = 'Y'
      AND ca.ca_gmt_offset BETWEEN -9.00 AND -5.00
      AND cs.cs_ship_date_sk BETWEEN 2450840 AND 2450900
      AND cs.cs_list_price < 500
    GROUP BY ROLLUP(p.p_promo_name, ca.ca_state)
    HAVING SUM(cs.cs_ext_sales_price) > 1000
),
web_agg AS (
    SELECT
        p.p_promo_name AS promo_name,
        ca.ca_state AS state,
        w.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_quantity > 1
      AND ws.ws_ext_sales_price > 80
      AND p.p_discount_active = 'Y'
      AND w.web_state = ca.ca_state
      AND ca.ca_gmt_offset BETWEEN -9.00 AND -5.00
      AND ws.ws_ship_date_sk BETWEEN 2450840 AND 2450900
      AND ws.ws_list_price < 400
    GROUP BY CUBE(p.p_promo_name, ca.ca_state, w.web_site_sk)
    HAVING SUM(ws.ws_ext_sales_price) > 800
)
SELECT
    promo_name,
    state,
    total_sales,
    total_profit,
    order_cnt,
    source,
    ROW_NUMBER() OVER (PARTITION BY promo_name ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT
        promo_name,
        state,
        total_sales,
        total_profit,
        order_cnt,
        'catalog' AS source
    FROM catalog_agg
    WHERE total_sales IS NOT NULL
    UNION ALL
    SELECT
        promo_name,
        state,
        total_sales,
        total_profit,
        order_cnt,
        'web' AS source
    FROM web_agg
) AS combined
WHERE total_sales > (
    SELECT AVG(sales) FROM (
        SELECT SUM(cs.cs_ext_sales_price) AS sales
        FROM catalog_sales cs
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        WHERE p.p_discount_active = 'Y'
        UNION ALL
        SELECT SUM(ws.ws_ext_sales_price)
        FROM web_sales ws
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        WHERE p.p_discount_active = 'Y'
    ) AS sub
)
ORDER BY total_sales DESC, sales_rank
LIMIT 100
