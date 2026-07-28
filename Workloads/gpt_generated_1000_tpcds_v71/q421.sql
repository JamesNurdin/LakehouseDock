WITH sales_agg AS (
    SELECT
        d_sold.d_year,
        i.i_category,
        cp.cp_department,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_returns,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_returned_date_sk = d_sold.d_date_sk
       AND wr.wr_returned_time_sk = t_sold.t_time_sk
    WHERE i.i_units = 'Lb'
      AND cp.cp_type = 'Promo'
      AND d_sold.d_year BETWEEN 2000 AND 2002
    GROUP BY d_sold.d_year, i.i_category, cp.cp_department
)
SELECT
    d_year,
    i_category,
    cp_department,
    total_sales,
    total_returns,
    total_sales - total_returns AS net_sales,
    order_cnt,
    avg_discount,
    AVG(total_sales) OVER (PARTITION BY i_category ORDER BY d_year
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales_by_cat
FROM sales_agg
WHERE total_sales > 5000
ORDER BY net_sales DESC
LIMIT 100
