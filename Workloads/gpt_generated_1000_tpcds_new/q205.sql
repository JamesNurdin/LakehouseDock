/*
Goal: Compare total net loss and return quantity by return reason for the year 2001 across catalog and web channels, using deep joins, lateral subqueries, and a UNION DISTINCT to deduplicate aggregated results.
*/
WITH catalog_part AS (
   SELECT
          d_cr.d_year AS year,
          r_cr.r_reason_desc AS reason,
          SUM(cr.cr_net_loss) AS net_loss,
          SUM(cr.cr_return_quantity) AS return_qty
   FROM catalog_returns cr
   JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
   JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
   JOIN item i_cr
        ON cr.cr_item_sk = i_cr.i_item_sk
   JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
   JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
   CROSS JOIN LATERAL (
        SELECT avg(cs2.cs_sales_price) AS avg_price
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i_cr.i_item_sk
   ) avg_price_sub
   WHERE d_cr.d_year = 2001
   GROUP BY d_cr.d_year, r_cr.r_reason_desc
),
web_part AS (
   SELECT
          d_wr.d_year AS year,
          r_wr.r_reason_desc AS reason,
          SUM(wr.wr_net_loss) AS net_loss,
          SUM(wr.wr_return_quantity) AS return_qty
   FROM web_returns wr
   JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
   JOIN item i_wr
        ON wr.wr_item_sk = i_wr.i_item_sk
   JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
   CROSS JOIN LATERAL (
        SELECT avg(cs2.cs_sales_price) AS avg_price
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i_wr.i_item_sk
   ) avg_price_sub
   WHERE d_wr.d_year = 2001
   GROUP BY d_wr.d_year, r_wr.r_reason_desc
)
SELECT
       year,
       reason,
       SUM(net_loss) AS total_net_loss,
       SUM(return_qty) AS total_return_qty
FROM (
       SELECT * FROM catalog_part
       UNION DISTINCT
       SELECT * FROM web_part
) combined
GROUP BY year, reason
ORDER BY year, total_net_loss DESC
