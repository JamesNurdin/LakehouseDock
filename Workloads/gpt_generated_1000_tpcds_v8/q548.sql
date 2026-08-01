WITH
    ws_sample AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    order_numbers_with_web_returns AS (
        SELECT DISTINCT ws.ws_order_number
        FROM ws_sample ws
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    ),
    order_numbers_with_catalog_returns AS (
        SELECT DISTINCT cr.cr_order_number
        FROM catalog_returns cr
        WHERE cr.cr_returned_date_sk IS NOT NULL
    ),
    order_numbers_excluding_catalog AS (
        SELECT ws_order_number
        FROM order_numbers_with_web_returns
        EXCEPT
        SELECT cr_order_number
        FROM order_numbers_with_catalog_returns
    ),
    order_numbers_in_both AS (
        SELECT ws_order_number
        FROM order_numbers_with_web_returns
        INTERSECT
        SELECT cr_order_number
        FROM order_numbers_with_catalog_returns
    )
SELECT
    ws.ws_order_number,
    d.d_date,
    i.i_product_name,
    sm.sm_type,
    r.r_reason_desc,
    ws.ws_net_profit,
    ws.ws_ext_sales_price,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ws.ws_net_profit DESC) AS profit_rank,
    (
        SELECT SUM(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_returned_date_sk = d.d_date_sk
    ) AS total_return_amount_for_item_date
FROM ws_sample ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = i.i_item_sk
LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                              AND cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'BrandX'
  AND sm.sm_code = 'AIR'
  AND ws.ws_order_number IN (SELECT ws_order_number FROM order_numbers_excluding_catalog)
  AND EXISTS (SELECT 1 FROM order_numbers_in_both oib WHERE oib.ws_order_number = ws.ws_order_number)
ORDER BY profit_rank, ws.ws_net_profit DESC
LIMIT 100
