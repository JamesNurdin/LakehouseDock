/*
Goal: Identify customers with significant catalog sales or web returns in 2022, enriched with a count of related opposite‑channel activity (store returns for sales, catalog sales for returns), rank them within their household‑demographic segment, and produce a deduplicated, ordered list of the top 100 records.
*/
WITH sales_2022 AS (
    SELECT
        c.c_customer_id,
        cs.cs_ext_sales_price AS metric_amount,
        (
            SELECT COUNT(*)
            FROM store_returns sr
            WHERE sr.sr_customer_sk = c.c_customer_sk
        ) AS metric_cnt,
        RANK() OVER (PARTITION BY c.c_current_hdemo_sk ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
      AND c.c_customer_sk IN (
          SELECT DISTINCT sr2.sr_customer_sk
          FROM store_returns sr2
          JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
          WHERE d2.d_year = 2022
      )
),
returns_2022 AS (
    SELECT DISTINCT
        c.c_customer_id,
        wr.wr_return_amt AS metric_amount,
        (
            SELECT COUNT(*)
            FROM catalog_sales cs2
            WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
        ) AS metric_cnt,
        RANK() OVER (PARTITION BY c.c_current_hdemo_sk ORDER BY wr.wr_return_amt DESC) AS sales_rank
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
      AND c.c_customer_sk IN (
          SELECT sr3.sr_customer_sk
          FROM store_returns sr3
          JOIN date_dim d3 ON sr3.sr_returned_date_sk = d3.d_date_sk
          WHERE d3.d_year = 2021
      )
)
SELECT *
FROM (
    SELECT c_customer_id, metric_amount, metric_cnt, sales_rank FROM sales_2022
    UNION
    SELECT c_customer_id, metric_amount, metric_cnt, sales_rank FROM returns_2022
) combined
ORDER BY metric_amount DESC, metric_cnt DESC
LIMIT 100
