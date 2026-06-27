WITH sales_returns_agg AS (
    SELECT
        i.i_brand,
        i.i_category,
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
        SUM(ws.ws_net_profit) AS total_profit,
        COALESCE(SUM(wr.wr_return_quantity), 0) AS total_quantity_returned,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    GROUP BY
        i.i_brand,
        i.i_category,
        i.i_item_id,
        i.i_product_name
)
SELECT
    i_brand,
    i_category,
    i_item_id,
    i_product_name,
    total_quantity_sold,
    total_sales_amount,
    total_discount_amount,
    total_profit,
    total_quantity_returned,
    total_return_amount,
    total_return_loss,
    (total_quantity_returned / NULLIF(total_quantity_sold, 0)) AS return_rate,
    (total_sales_amount - total_return_amount) AS net_sales_amount,
    (total_profit - total_return_loss) AS net_profit_after_returns,
    (total_discount_amount / NULLIF(total_sales_amount, 0)) AS avg_discount_pct,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY (total_profit - total_return_loss) DESC) AS brand_profit_rank
FROM sales_returns_agg
ORDER BY net_profit_after_returns DESC
LIMIT 20
