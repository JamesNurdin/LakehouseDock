WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        d.d_year,
        d.d_fy_quarter_seq,
        d.d_current_week,
        d.d_holiday,
        i.i_brand,
        i.i_units
    FROM catalog_sales cs
    INNER JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_fy_quarter_seq = 8
      AND d.d_current_week = 'N'
      AND d.d_holiday = 'N'
      AND d.d_month_seq BETWEEN 30 AND 36
      AND i.i_brand = 'importobrand #6'
      AND i.i_units = 'Box'
      AND cs.cs_quantity >= 2
      AND cs.cs_net_profit > 0
) 
SELECT
    filtered_sales.d_year,
    filtered_sales.i_brand,
    filtered_sales.i_units,
    SUM(filtered_sales.cs_net_paid) AS total_net_paid,
    AVG(filtered_sales.cs_ext_sales_price) AS avg_ext_sales_price,
    COUNT(*) AS sales_count,
    MAX(filtered_sales.cs_ext_discount_amt) AS max_ext_discount_amt
FROM filtered_sales
GROUP BY
    filtered_sales.d_year,
    filtered_sales.i_brand,
    filtered_sales.i_units
ORDER BY total_net_paid DESC
LIMIT 100
