WITH sales_agg AS (
    SELECT
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit
    FROM catalog_sales
    GROUP BY cs_item_sk
),
returns_agg AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_net_loss) AS total_net_loss
    FROM catalog_returns
    GROUP BY cr_item_sk
),
item_sales_returns AS (
    SELECT
        i.i_brand,
        i.i_brand_id,
        s.total_sales,
        s.total_quantity,
        s.total_net_profit,
        r.total_return_amount,
        r.total_return_quantity,
        r.total_net_loss
    FROM item i
    LEFT JOIN sales_agg s
        ON s.cs_item_sk = i.i_item_sk
    LEFT JOIN returns_agg r
        ON r.cr_item_sk = i.i_item_sk
)
SELECT
    i_brand,
    i_brand_id,
    SUM(COALESCE(total_sales, 0)) AS total_sales,
    SUM(COALESCE(total_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(total_quantity, 0)) AS total_quantity,
    SUM(COALESCE(total_return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(total_net_profit, 0)) - SUM(COALESCE(total_net_loss, 0)) AS net_profit_after_returns,
    CASE
        WHEN SUM(COALESCE(total_quantity, 0)) = 0 THEN 0
        ELSE SUM(COALESCE(total_return_quantity, 0)) / CAST(SUM(COALESCE(total_quantity, 0)) AS DOUBLE)
    END AS return_rate
FROM item_sales_returns
GROUP BY i_brand, i_brand_id
HAVING SUM(COALESCE(total_sales, 0)) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 20
