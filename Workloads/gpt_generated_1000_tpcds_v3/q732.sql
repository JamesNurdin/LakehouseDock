WITH sales_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        i.i_product_name AS product_name,
        ws.ws_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        SUM(ws.ws_quantity) AS quantity,
        SUM(ws.ws_ext_sales_price) AS amount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'
      AND i.i_rec_start_date < DATE '2001-01-01'
      AND t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_cost > 5000
      )
    GROUP BY ws.ws_item_sk, i.i_product_name, ws.ws_promo_sk, p.p_promo_name
)

SELECT
    sa.item_sk,
    sa.product_name,
    'Sale' AS activity_type,
    sa.quantity,
    sa.amount,
    sa.promo_name,
    (SELECT MAX(p3.p_cost) FROM promotion p3 WHERE p3.p_item_sk = sa.item_sk) AS max_promo_cost
FROM sales_agg sa

UNION ALL

SELECT
    ra.item_sk,
    ra.product_name,
    'Return' AS activity_type,
    ra.quantity,
    ra.amount,
    ra.promo_name,
    (SELECT MAX(p3.p_cost) FROM promotion p3 WHERE p3.p_item_sk = ra.item_sk) AS max_promo_cost
FROM (
    SELECT
        ws.ws_item_sk AS item_sk,
        i.i_product_name AS product_name,
        ws.ws_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        SUM(wr.wr_return_quantity) AS quantity,
        SUM(wr.wr_return_amt) AS amount
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'
      AND i.i_rec_start_date < DATE '2001-01-01'
      AND t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_cost > 5000
      )
    GROUP BY ws.ws_item_sk, i.i_product_name, ws.ws_promo_sk, p.p_promo_name
) ra
ORDER BY activity_type DESC, amount DESC
LIMIT 100
