WITH returns_agg AS (
    SELECT
        cr_item_sk,
        cr_order_number,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_item_sk, cr_order_number
),
catalog_sales_agg AS (
    SELECT
        i.i_brand,
        i.i_category,
        SUM(cs.cs_net_paid - COALESCE(r.total_return_amount, 0)) AS net_sales_amount,
        SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN returns_agg r
        ON cs.cs_item_sk = r.cr_item_sk
        AND cs.cs_order_number = r.cr_order_number
    GROUP BY i.i_brand, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_brand,
        i.i_category,
        SUM(ws.ws_net_paid) AS net_sales_amount,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_brand, i.i_category
),
combined AS (
    SELECT i_brand, i_category, net_sales_amount, net_profit FROM catalog_sales_agg
    UNION ALL
    SELECT i_brand, i_category, net_sales_amount, net_profit FROM web_sales_agg
)
SELECT
    i_brand AS brand,
    i_category AS category,
    SUM(net_sales_amount) AS total_net_sales,
    SUM(net_profit) AS total_net_profit
FROM combined
GROUP BY i_brand, i_category
ORDER BY total_net_sales DESC
LIMIT 20
