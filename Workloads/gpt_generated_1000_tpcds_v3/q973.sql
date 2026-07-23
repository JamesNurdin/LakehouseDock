WITH filtered_sales AS (
    SELECT
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_item_sk,
        cs_catalog_page_sk,
        cs_quantity,
        cs_net_paid,
        cs_net_profit,
        cs_ext_sales_price,
        cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 0
)
SELECT
    cp.cp_type,
    i.i_brand,
    d_sold.d_year,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS total_positive_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS overall_avg_net_profit,
    CASE
        WHEN AVG(cs.cs_net_profit) > (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_comparison
FROM filtered_sales cs
INNER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
INNER JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
INNER JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
INNER JOIN date_dim d_common
    ON cp.cp_start_date_sk = d_common.d_date_sk
INNER JOIN web_page wp
    ON wp.wp_creation_date_sk = d_common.d_date_sk
INNER JOIN web_site ws
    ON ws.web_open_date_sk = d_common.d_date_sk
WHERE
    d_sold.d_year = 1999
    AND t.t_am_pm = 'PM'
    AND cp.cp_type = 'quarterly'
    AND i.i_brand_id = 5
GROUP BY
    cp.cp_type,
    i.i_brand,
    d_sold.d_year
ORDER BY
    total_sales DESC
LIMIT 100
