WITH all_sales AS (
    SELECT cs.cs_item_sk AS item_sk,
           d.d_year,
           d.d_month_seq,
           cs.cs_ext_sales_price AS sales_amount,
           cs.cs_ext_discount_amt AS discount_amount,
           cs.cs_net_profit AS profit_amount,
           cs.cs_quantity AS quantity_sold
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT ss.ss_item_sk,
           d.d_year,
           d.d_month_seq,
           ss.ss_ext_sales_price,
           ss.ss_ext_discount_amt,
           ss.ss_net_profit,
           ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT ws.ws_item_sk,
           d.d_year,
           d.d_month_seq,
           ws.ws_ext_sales_price,
           ws.ws_ext_discount_amt,
           ws.ws_net_profit,
           ws.ws_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
all_returns AS (
    SELECT cr.cr_item_sk AS item_sk,
           d.d_year,
           d.d_month_seq,
           cr.cr_return_amount AS return_amount,
           cr.cr_return_quantity AS return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT sr.sr_item_sk,
           d.d_year,
           d.d_month_seq,
           sr.sr_return_amt,
           sr.sr_return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT wr.wr_item_sk,
           d.d_year,
           d.d_month_seq,
           wr.wr_return_amt,
           wr.wr_return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
),
sales_agg AS (
    SELECT item_sk,
           d_year,
           d_month_seq,
           sum(sales_amount) AS total_sales,
           sum(discount_amount) AS total_discount,
           sum(profit_amount) AS total_profit,
           sum(quantity_sold) AS total_quantity
    FROM all_sales
    GROUP BY item_sk, d_year, d_month_seq
),
returns_agg AS (
    SELECT item_sk,
           d_year,
           d_month_seq,
           sum(return_amount) AS total_return_amount,
           sum(return_quantity) AS total_return_quantity
    FROM all_returns
    GROUP BY item_sk, d_year, d_month_seq
),
final_agg AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_category,
           i.i_class,
           i.i_brand,
           i.i_manufact,
           s.d_year,
           s.d_month_seq,
           s.total_sales,
           s.total_discount,
           s.total_profit,
           coalesce(r.total_return_amount, 0) AS total_return_amount,
           coalesce(r.total_return_quantity, 0) AS total_return_quantity
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.item_sk = r.item_sk AND s.d_year = r.d_year AND s.d_month_seq = r.d_month_seq
    JOIN item i ON s.item_sk = i.i_item_sk
    WHERE s.d_year BETWEEN 2001 AND 2002
)
SELECT *
FROM (
    SELECT *,
           (total_sales - total_discount) AS net_sales,
           (total_sales - total_discount - total_return_amount) AS net_sales_after_returns,
           (total_profit - (total_return_amount * 0.05)) AS adjusted_profit,
           CASE
               WHEN (total_sales - total_discount - total_return_amount) = 0 THEN 0
               ELSE (total_profit - (total_return_amount * 0.05)) / (total_sales - total_discount - total_return_amount)
           END AS profit_margin,
           (total_sales - total_discount - total_return_amount) /
               sum(total_sales - total_discount - total_return_amount) over (partition by d_year, d_month_seq) AS sales_share,
           row_number() over (partition by d_year, d_month_seq, i_category order by (total_sales - total_discount - total_return_amount) desc) AS rank_in_category
    FROM final_agg
) sub
WHERE rank_in_category <= 5
ORDER BY d_year DESC, d_month_seq DESC, i_category, rank_in_category
