SELECT
    i_item_id,
    i_product_name,
    total_sold_qty,
    total_sold_amt,
    total_return_qty,
    total_return_amt,
    net_profit,
    return_rate_pct,
    ROW_NUMBER() OVER (ORDER BY net_profit DESC) AS profit_rank,
    CASE
        WHEN i_category = 'Electronics' THEN 'Tech'
        ELSE 'Other'
    END AS category_group
FROM (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        SUM(cs.cs_quantity) AS total_sold_qty,
        SUM(cs.cs_ext_sales_price) AS total_sold_amt,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COALESCE(SUM(wr.wr_return_quantity), 0) AS total_return_qty,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amt,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
        (SUM(cs.cs_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) AS net_profit,
        CASE WHEN SUM(cs.cs_quantity) = 0 THEN 0
            ELSE (COALESCE(SUM(wr.wr_return_quantity), 0) / SUM(cs.cs_quantity)) * 100
        END AS return_rate_pct
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON cs.cs_item_sk = wr.wr_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_category
) t
ORDER BY net_profit DESC
LIMIT 20
