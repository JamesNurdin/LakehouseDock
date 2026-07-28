WITH returns_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        SUM(cr.cr_return_amount) AS total_amount,
        'return' AS activity_type
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc = 'Customer not interested'
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_product_name
),
sales_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        SUM(ss.ss_net_paid) AS total_amount,
        'sale' AS activity_type
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND s.s_market_manager = 'Richard Bell'
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_product_name
)
SELECT d_year,
       d_month_seq,
       i_item_id,
       i_product_name,
       total_amount,
       activity_type
FROM returns_monthly
UNION ALL
SELECT d_year,
       d_month_seq,
       i_item_id,
       i_product_name,
       total_amount,
       activity_type
FROM sales_monthly
ORDER BY d_year,
         d_month_seq,
         activity_type,
         total_amount DESC
LIMIT 100
