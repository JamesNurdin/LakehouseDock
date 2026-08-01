WITH sales_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        r.r_reason_desc,
        ss.ss_quantity,
        ss.ss_net_paid,
        sr.sr_net_loss,
        concat(i.i_brand, '-', i.i_category) AS brand_category,
        substring(i.i_product_name, 1, 15) AS prod_prefix,
        regexp_extract(i.i_product_name, '[0-9]+', 1) AS product_digits,
        CASE WHEN regexp_like(i.i_product_name, '[A-Z]{2,}') THEN 1 ELSE 0 END AS has_upper_seq
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE i.i_product_name LIKE '%PROD%'
      AND regexp_like(i.i_product_name, '[0-9]{2,}')
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    i_brand,
    r_reason_desc,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_net_paid) AS total_sales,
    SUM(COALESCE(sr_net_loss, 0)) AS total_net_loss,
    COUNT(*) AS transaction_count
FROM sales_returns
GROUP BY CUBE (d_year, d_month_seq, i_category, i_brand, r_reason_desc)
ORDER BY total_sales DESC
LIMIT 100
