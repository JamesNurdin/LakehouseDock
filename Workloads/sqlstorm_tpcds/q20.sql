WITH store_agg AS (
    SELECT
        d.d_year,
        s.s_store_name,
        i.i_category,
        p.p_promo_name,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_distinct_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY d.d_year, s.s_store_name, i.i_category, p.p_promo_name
), catalog_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_distinct_customers
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY d.d_year, i.i_category, p.p_promo_name
), web_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_distinct_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY d.d_year, i.i_category, p.p_promo_name
)
SELECT
    COALESCE(s.d_year, c.d_year, w.d_year) AS sales_year,
    s.s_store_name,
    COALESCE(s.i_category, c.i_category, w.i_category) AS category,
    COALESCE(s.p_promo_name, c.p_promo_name, w.p_promo_name) AS promo_name,
    s.store_net_profit,
    c.catalog_net_profit,
    w.web_net_profit,
    s.store_distinct_customers,
    c.catalog_distinct_customers,
    w.web_distinct_customers,
    COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit
FROM store_agg s
FULL OUTER JOIN catalog_agg c
    ON s.d_year = c.d_year
   AND s.i_category = c.i_category
   AND s.p_promo_name = c.p_promo_name
FULL OUTER JOIN web_agg w
    ON COALESCE(s.d_year, c.d_year) = w.d_year
   AND COALESCE(s.i_category, c.i_category) = w.i_category
   AND COALESCE(s.p_promo_name, c.p_promo_name) = w.p_promo_name
WHERE COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) > 0
ORDER BY sales_year, total_net_profit DESC
LIMIT 200
