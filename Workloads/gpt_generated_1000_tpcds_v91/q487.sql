WITH item_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_manufact_id,
        i.i_manufact,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_sales_orders,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
    FROM item i
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    WHERE i.i_wholesale_cost > 5.00
      AND ws.ws_ship_customer_sk IN (11491160, 10928779, 6215630)
      AND cr.cr_return_amount > 10.00
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_manufact_id,
        i.i_manufact
),
manufact_agg AS (
    SELECT
        i_manufact_id,
        i_manufact,
        SUM(total_sales) AS manuf_total_sales,
        SUM(total_return_amount) AS manuf_total_returns,
        AVG(total_sales - total_return_amount) AS avg_net_sales,
        CASE
            WHEN SUM(total_sales) > 1000000 THEN 'HIGH'
            WHEN SUM(total_sales) > 500000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS sales_category
    FROM item_agg
    GROUP BY i_manufact_id, i_manufact
)
SELECT
    ma.i_manufact_id,
    ma.i_manufact,
    ma.manuf_total_sales,
    ma.manuf_total_returns,
    ma.avg_net_sales,
    ma.sales_category,
    RANK() OVER (PARTITION BY ma.sales_category ORDER BY ma.manuf_total_sales DESC) AS category_rank,
    ROW_NUMBER() OVER (ORDER BY ma.manuf_total_sales DESC) AS overall_rank
FROM manufact_agg ma
WHERE ma.avg_net_sales > 1000.00
ORDER BY ma.manuf_total_sales DESC
LIMIT 100
