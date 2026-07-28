WITH overall_avg AS (
    SELECT AVG(cs2.cs_sales_price) AS avg_price
    FROM catalog_sales cs2
)
SELECT
    s.s_store_name,
    i.i_category,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) AS net_profit,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    COUNT(cr.cr_return_amount) AS return_cnt,
    CASE
        WHEN AVG(cs.cs_sales_price) > (SELECT avg_price FROM overall_avg) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS price_vs_avg,
    CASE
        WHEN SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) > 0 THEN 'POSITIVE'
        ELSE 'NEGATIVE'
    END AS profit_status
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
WHERE d_sold.d_year = 2001
  AND d_sold.d_month_seq = 12
  AND cp.cp_type = 'PROMO'
  AND s.s_gmt_offset = -5.00
  AND i.i_brand = 'BrandX'
GROUP BY s.s_store_name, i.i_category, d_sold.d_year, d_sold.d_month_seq
ORDER BY net_profit DESC
LIMIT 100
