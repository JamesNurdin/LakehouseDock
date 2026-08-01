WITH
   src1 AS (
      SELECT
         cr.cr_returned_date_sk AS return_date_sk,
         ws.ws_sold_date_sk AS sold_date_sk,
         cd.cd_gender,
         cd.cd_marital_status,
         SUM(cr.cr_return_amount) AS total_return_amount,
         SUM(ws.ws_ext_sales_price) AS total_sales_amount,
         COUNT(*) AS txn_cnt,
         CASE 
            WHEN SUM(cr.cr_return_amount) > SUM(ws.ws_ext_sales_price) THEN 'MORE_RETURN'
            ELSE 'MORE_SALE'
         END AS dominant_side
      FROM catalog_returns cr
      JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
      JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
      WHERE cr.cr_return_amount > 50
        AND cr.cr_fee BETWEEN 5 AND 30
        AND ws.ws_ext_sales_price > 1000
        AND ws.ws_coupon_amt > 0
        AND cd.cd_purchase_estimate >= 5000
        AND cd.cd_dep_employed_count >= 2
      GROUP BY GROUPING SETS (
         (cd.cd_gender, cd.cd_marital_status, cr.cr_returned_date_sk, ws.ws_sold_date_sk),
         (cd.cd_gender, cd.cd_marital_status),
         (cd.cd_gender),
         ()
      )
   ),
   src2 AS (
      SELECT
         cr.cr_returned_date_sk AS return_date_sk,
         ws.ws_sold_date_sk AS sold_date_sk,
         cd.cd_gender,
         cd.cd_marital_status,
         SUM(cr.cr_return_amount) AS total_return_amount,
         SUM(ws.ws_ext_sales_price) AS total_sales_amount,
         COUNT(*) AS txn_cnt,
         CASE 
            WHEN SUM(cr.cr_return_amount) > SUM(ws.ws_ext_sales_price) THEN 'MORE_RETURN'
            ELSE 'MORE_SALE'
         END AS dominant_side
      FROM catalog_returns cr
      JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
      JOIN web_sales ws
        ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
      WHERE cr.cr_return_amount > 150
        AND cr.cr_fee BETWEEN 10 AND 40
        AND ws.ws_ext_sales_price > 2000
        AND ws.ws_coupon_amt > 50
        AND cd.cd_purchase_estimate >= 6000
        AND cd.cd_dep_employed_count >= 3
      GROUP BY GROUPING SETS (
         (cd.cd_gender, cd.cd_marital_status, cr.cr_returned_date_sk, ws.ws_sold_date_sk),
         (cd.cd_gender, cd.cd_marital_status),
         (cd.cd_gender),
         ()
      )
   ),
   united AS (
      SELECT * FROM src1
      UNION
      SELECT * FROM src2
   ),
   final AS (
      SELECT
         return_date_sk,
         sold_date_sk,
         cd_gender,
         cd_marital_status,
         total_return_amount,
         total_sales_amount,
         txn_cnt,
         dominant_side,
         RANK() OVER (PARTITION BY cd_gender ORDER BY total_return_amount DESC) AS return_rank,
         ROW_NUMBER() OVER (ORDER BY total_sales_amount DESC) AS sales_rownum,
         SUM(total_return_amount) OVER (
               PARTITION BY cd_gender
               ORDER BY return_date_sk
               ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
         ) AS moving_return_sum
      FROM united
   )
SELECT
   return_date_sk,
   sold_date_sk,
   cd_gender,
   cd_marital_status,
   total_return_amount,
   total_sales_amount,
   txn_cnt,
   dominant_side,
   return_rank,
   sales_rownum,
   moving_return_sum
FROM final
WHERE return_rank <= 5
ORDER BY cd_gender, return_rank, return_date_sk
