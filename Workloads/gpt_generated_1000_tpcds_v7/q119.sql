WITH catalog_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_profit,
        CASE WHEN SUM(cs.cs_net_paid_inc_ship) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY 'catalog' ORDER BY SUM(cs.cs_net_paid_inc_ship) DESC) AS rank,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_salutation = 'Mr.'
      AND cs.cs_ext_tax > 0
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
web_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(ws.ws_net_paid_inc_ship) AS total_net_profit,
        CASE WHEN SUM(ws.ws_net_paid_inc_ship) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY 'web' ORDER BY SUM(ws.ws_net_paid_inc_ship) DESC) AS rank,
        'web' AS source
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'content'
      AND ws.ws_ext_tax > 0
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT
    customer_id,
    customer_name,
    total_net_profit,
    profit_category,
    source,
    rank
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
) AS combined
ORDER BY total_net_profit DESC
LIMIT 100
