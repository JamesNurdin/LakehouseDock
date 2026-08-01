WITH catalog_summary AS (
    SELECT d.d_date AS sales_date,
           'Catalog' AS channel,
           SUM(cs.cs_net_paid) AS total_net_paid,
           SUM(cs.cs_quantity) AS total_quantity,
           SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
      AND i.i_category = 'Electronics'
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_date
),
web_summary AS (
    SELECT d.d_date AS sales_date,
           'Web' AS channel,
           SUM(ws.ws_net_paid) AS total_net_paid,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
      AND i.i_category = 'Electronics'
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_date
)
SELECT sales_date,
       channel,
       total_net_paid,
       total_quantity,
       total_net_profit
FROM catalog_summary
UNION ALL
SELECT sales_date,
       channel,
       total_net_paid,
       total_quantity,
       total_net_profit
FROM web_summary
ORDER BY sales_date, channel
LIMIT 100
