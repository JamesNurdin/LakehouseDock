WITH web_sales_agg AS (
    SELECT i.i_item_id,
           i.i_product_name,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, i.i_product_name
),
store_returns_agg AS (
    SELECT i.i_item_id,
           i.i_product_name,
           SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
           SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT result.item_id,
       result.product_name,
       result.metric,
       result.amount
FROM (
    SELECT wa.i_item_id AS item_id,
           wa.i_product_name AS product_name,
           'Web Sales' AS metric,
           wa.total_sales AS amount
    FROM web_sales_agg wa
    WHERE wa.total_sales > (SELECT AVG(total_sales) FROM web_sales_agg)
    UNION ALL
    SELECT ra.i_item_id AS item_id,
           ra.i_product_name AS product_name,
           'Store Returns' AS metric,
           ra.total_net_loss AS amount
    FROM store_returns_agg ra
    WHERE ra.total_net_loss > (SELECT AVG(total_net_loss) FROM store_returns_agg)
) AS result
ORDER BY result.amount DESC
LIMIT 100
