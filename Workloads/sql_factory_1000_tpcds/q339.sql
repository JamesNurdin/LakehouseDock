WITH brand_sales AS (
    SELECT
        i.i_brand,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_returns
    FROM item i
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_brand, i.i_category
)
SELECT
    bs.i_brand AS brand,
    bs.i_category AS category,
    bs.total_sales,
    bs.total_discount,
    bs.total_returns,
    bs.total_sales - bs.total_returns AS net_sales,
    CASE WHEN bs.total_discount > 0 THEN 'Discounted' ELSE 'Full Price' END AS discount_status,
    DENSE_RANK() OVER (ORDER BY bs.total_sales - bs.total_returns DESC) AS sales_rank,
    SUM(bs.total_sales - bs.total_returns) OVER (ORDER BY bs.total_sales - bs.total_returns DESC ROWS UNBOUNDED PRECEDING) AS cumulative_net_sales
FROM brand_sales bs
ORDER BY sales_rank
LIMIT 15
