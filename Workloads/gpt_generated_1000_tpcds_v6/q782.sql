WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        td.t_sub_shift AS sub_shift,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        'sales' AS source
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'PM'
      AND i.i_brand = 'BrandX'
    GROUP BY i.i_category, td.t_sub_shift
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT * FROM sales_agg
UNION ALL
SELECT
    i.i_category AS category,
    td.t_sub_shift AS sub_shift,
    -SUM(wr.wr_return_amt_inc_tax) AS total_sales,
    -SUM(wr.wr_net_loss) AS total_profit,
    'returns' AS source
FROM web_returns wr
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE td.t_am_pm = 'PM'
  AND r.r_reason_desc LIKE '%price%'
GROUP BY i.i_category, td.t_sub_shift
HAVING SUM(wr.wr_return_amt_inc_tax) > 5000
ORDER BY category, sub_shift, source
