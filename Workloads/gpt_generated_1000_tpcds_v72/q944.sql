/* goal: Compare total promotional sales and return amounts per item for the year 2020, focusing on active promotions, and list the top 100 records by amount. */
WITH recent_dates AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq
    FROM   date_dim
    WHERE  d_year = 2020
)
SELECT
    rd.d_year AS year,
    rd.d_month_seq AS month,
    i.i_item_id AS item_id,
    p.p_promo_name AS promo_name,
    'sales' AS record_type,
    SUM(cs.cs_ext_sales_price) AS total_amount
FROM   catalog_sales cs
JOIN   recent_dates rd
       ON cs.cs_sold_date_sk = rd.d_date_sk
JOIN   item i
       ON cs.cs_item_sk = i.i_item_sk
JOIN   promotion p
       ON cs.cs_promo_sk = p.p_promo_sk
WHERE  p.p_discount_active = 'Y'
  AND  p.p_response_target > 0
GROUP BY
    rd.d_year,
    rd.d_month_seq,
    i.i_item_id,
    p.p_promo_name

UNION ALL

SELECT
    rd.d_year AS year,
    rd.d_month_seq AS month,
    i.i_item_id AS item_id,
    NULL AS promo_name,
    'return' AS record_type,
    SUM(wr.wr_return_amt) AS total_amount
FROM   web_returns wr
JOIN   recent_dates rd
       ON wr.wr_returned_date_sk = rd.d_date_sk
JOIN   item i
       ON wr.wr_item_sk = i.i_item_sk
WHERE  EXISTS (
           SELECT 1
           FROM   promotion p2
           WHERE  p2.p_item_sk = wr.wr_item_sk
             AND  p2.p_discount_active = 'Y'
             AND  p2.p_response_target > 0
       )
GROUP BY
    rd.d_year,
    rd.d_month_seq,
    i.i_item_id

ORDER BY
    year DESC,
    month DESC,
    total_amount DESC
LIMIT 100
