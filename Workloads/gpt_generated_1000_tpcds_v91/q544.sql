WITH recent_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_fee,
        cr.cr_net_loss
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 150.00
      AND cr.cr_return_quantity >= 2
      AND cr.cr_fee < 300.00
),
joined_data AS (
    SELECT
        d_ret.d_year,
        i.i_item_id,
        i.i_product_name,
        cc.cc_name,
        cc.cc_state,
        cr.cr_return_amount,
        ws.ws_ext_sales_price,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_order_number
    FROM recent_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_sold_date_sk = d_ret.d_date_sk
    WHERE i.i_brand_id IN (10008011, 5002002)
      AND d_ret.d_year = 2002
      AND ws.ws_net_paid_inc_ship_tax > 2000.00
),
agg AS (
    SELECT
        d_year,
        i_item_id,
        i_product_name,
        cc_name,
        cc_state,
        COUNT(*) AS return_count,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_amount) AS avg_return_amount,
        MIN(cr_return_amount) AS min_return_amount,
        MAX(cr_return_amount) AS max_return_amount,
        SUM(ws_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM joined_data
    GROUP BY d_year, i_item_id, i_product_name, cc_name, cc_state
)
SELECT
    a.d_year,
    a.i_item_id,
    a.i_product_name,
    a.cc_name,
    a.cc_state,
    a.return_count,
    a.total_return_amount,
    a.avg_return_amount,
    a.min_return_amount,
    a.max_return_amount,
    a.total_sales_amount,
    a.distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY a.i_item_id ORDER BY a.total_return_amount DESC) AS return_rank_by_item,
    (SELECT SUM(ws2.ws_ext_sales_price)
     FROM web_sales ws2
     JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
     WHERE i2.i_item_id = a.i_item_id) AS total_sales_for_item_all_time
FROM agg a
ORDER BY a.total_return_amount DESC
LIMIT 100
