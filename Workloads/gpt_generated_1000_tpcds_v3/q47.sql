WITH cs_agg AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_catalog_page_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity
    FROM
        catalog_sales cs
    WHERE
        cs.cs_ext_ship_cost > 500
        AND cs.cs_ext_sales_price > 1000
        AND cs.cs_quantity > 1
    GROUP BY
        cs.cs_bill_customer_sk,
        cs.cs_catalog_page_sk
),
wr_agg AS (
    SELECT
        wr.wr_refunded_customer_sk,
        wr.wr_web_page_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_fee) AS total_fee,
        SUM(wr.wr_net_loss) AS total_loss
    FROM
        web_returns wr
    WHERE
        wr.wr_fee > 20
        AND wr.wr_return_amt > 0
        AND wr.wr_return_quantity > 0
    GROUP BY
        wr.wr_refunded_customer_sk,
        wr.wr_web_page_sk
)
SELECT
    cp.cp_department,
    cp.cp_catalog_page_number,
    wp.wp_type,
    SUM(cs_agg.total_sales) AS sum_sales,
    SUM(cs_agg.total_profit) AS sum_profit,
    SUM(wr_agg.total_return_amt) AS sum_return_amt,
    SUM(wr_agg.total_fee) AS sum_return_fee,
    SUM(wr_agg.total_loss) AS sum_return_loss,
    (SUM(cs_agg.total_sales) - SUM(wr_agg.total_return_amt) - SUM(wr_agg.total_fee)) AS net_sales,
    (SUM(cs_agg.total_profit) - SUM(wr_agg.total_loss)) AS net_profit
FROM
    cs_agg
JOIN
    customer c ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
JOIN
    catalog_page cp ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN
    web_page wp ON wp.wp_customer_sk = c.c_customer_sk
JOIN
    wr_agg ON wr_agg.wr_refunded_customer_sk = c.c_customer_sk
        AND wr_agg.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    cp.cp_department = 'DEPARTMENT'
    AND cp.cp_catalog_page_number BETWEEN 10 AND 20
    AND wp.wp_char_count > 500
GROUP BY
    cp.cp_department,
    cp.cp_catalog_page_number,
    wp.wp_type
HAVING
    (SUM(cs_agg.total_sales) - SUM(wr_agg.total_return_amt) - SUM(wr_agg.total_fee)) > 5000
ORDER BY
    net_sales DESC
LIMIT 100
