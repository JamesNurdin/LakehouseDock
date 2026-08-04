WITH sales_item AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        i.i_brand,
        i.i_category,
        i.i_product_name,
        cr.cr_return_amount,
        cr.cr_return_quantity
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    WHERE ws.ws_net_paid > 1000
      AND i.i_brand_id IN (5002002, 6016006)
      AND i.i_size = 'medium'
      AND ws.ws_coupon_amt < 100
)
SELECT
    si.i_brand,
    si.i_category,
    si.i_product_name,
    SUM(si.ws_ext_sales_price) AS total_sales,
    SUM(COALESCE(si.cr_return_amount, 0)) AS total_return_amount,
    AVG(si.ws_net_paid) AS avg_net_paid,
    RANK() OVER (PARTITION BY si.i_brand ORDER BY SUM(si.ws_ext_sales_price) DESC) AS brand_sales_rank
FROM sales_item si
WHERE si.ws_order_number NOT IN (
    SELECT cr2.cr_order_number
    FROM catalog_returns cr2
    WHERE cr2.cr_return_amount > 200
)
GROUP BY si.i_brand, si.i_category, si.i_product_name
HAVING SUM(si.ws_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
