WITH sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_category AS category,
        i.i_brand AS brand,
        d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        SUM(ws.ws_ext_sales_price) AS amount,
        SUM(ws.ws_quantity) AS quantity,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customer_count
    FROM web_sales ws
    INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND d.d_quarter_seq = 10
    GROUP BY i.i_item_id, i.i_category, i.i_brand, d.d_year, d.d_quarter_seq
    HAVING SUM(ws.ws_ext_sales_price) > 10000
       AND COUNT(DISTINCT ws.ws_bill_customer_sk) > 5
),
returns_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_category AS category,
        i.i_brand AS brand,
        d.d_year AS year,
        d.d_quarter_seq AS quarter_seq,
        SUM(wr.wr_return_amt) AS amount,
        SUM(wr.wr_return_quantity) AS quantity,
        COUNT(DISTINCT wr.wr_refunded_customer_sk) AS distinct_customer_count
    FROM web_returns wr
    INNER JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    INNER JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    INNER JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND d.d_quarter_seq = 10
    GROUP BY i.i_item_id, i.i_category, i.i_brand, d.d_year, d.d_quarter_seq
    HAVING SUM(wr.wr_return_amt) > 2000
       AND COUNT(DISTINCT wr.wr_refunded_customer_sk) > 2
)
SELECT 'sale'   AS transaction_type,
       s.item_id,
       s.category,
       s.brand,
       s.year,
       s.quarter_seq,
       s.amount,
       s.quantity,
       s.distinct_customer_count
FROM sales_agg s
UNION ALL
SELECT 'return' AS transaction_type,
       r.item_id,
       r.category,
       r.brand,
       r.year,
       r.quarter_seq,
       r.amount,
       r.quantity,
       r.distinct_customer_count
FROM returns_agg r
