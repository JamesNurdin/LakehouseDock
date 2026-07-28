/*
  Goal: Calculate the net sales (sales minus returns) for each promotion in the year 2001, 
  considering only sales that occurred on days when the inventory had more than 500 items on hand. 
  The result lists promotions with positive net sales, ordered by net sales descending, limited to the top 100.
*/
WITH sales_data AS (
    SELECT p.p_promo_id AS promo_id,
           SUM(ws.ws_ext_sales_price) AS sales_amount
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM inventory i
          JOIN date_dim d_inv
              ON i.inv_date_sk = d_inv.d_date_sk
          WHERE d_inv.d_date_sk = ws.ws_sold_date_sk
            AND i.inv_quantity_on_hand > 500
      )
    GROUP BY p.p_promo_id
),
returns_data AS (
    SELECT p.p_promo_id AS promo_id,
           -SUM(wr.wr_return_amt) AS sales_amount
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY p.p_promo_id
),
combined AS (
    SELECT promo_id, sales_amount FROM sales_data
    UNION ALL
    SELECT promo_id, sales_amount FROM returns_data
)
SELECT promo_id,
       SUM(sales_amount) AS net_sales
FROM combined
GROUP BY promo_id
HAVING SUM(sales_amount) > 0
ORDER BY net_sales DESC
LIMIT 100
