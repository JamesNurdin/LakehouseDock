WITH sales AS (
   SELECT d.d_year AS year,
          SUM(ws.ws_ext_sales_price) AS amount,
          'sales' AS src
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE p.p_discount_active = 'Y'
     AND EXISTS (
         SELECT 1
         FROM customer c
         JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
         WHERE c.c_customer_sk = ws.ws_bill_customer_sk
           AND cd.cd_gender = 'M'
     )
   GROUP BY d.d_year
),
returns AS (
   SELECT d.d_year AS year,
          SUM(wr.wr_return_amt) AS amount,
          'returns' AS src
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE p.p_discount_active = 'Y'
     AND d.d_holiday = 'N'
   GROUP BY d.d_year
)
SELECT year, amount, src
FROM sales
UNION ALL
SELECT year, amount, src
FROM returns
ORDER BY year, src
LIMIT 100
