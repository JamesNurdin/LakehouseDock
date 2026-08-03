WITH preferred_customers AS (
    SELECT c_customer_sk
    FROM tpcds.customer
    WHERE c_preferred_cust_flag = 'Y'
),
sales_agg AS (
    SELECT
        CONCAT(i.i_brand, '-', i.i_category) AS brand_category,
        t.t_sub_shift AS sub_shift,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit_amount,
        COUNT(*) AS sales_cnt
    FROM tpcds.store_sales ss
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_customer_sk IN (SELECT c_customer_sk FROM preferred_customers)
      AND REGEXP_LIKE(i.i_product_name, 'Premium')
      AND i.i_color LIKE '%Red%'
    GROUP BY CONCAT(i.i_brand, '-', i.i_category), t.t_sub_shift
),
returns_agg AS (
    SELECT
        CONCAT(i.i_brand, '-', i.i_category) AS brand_category,
        t.t_sub_shift AS sub_shift,
        SUM(wr.wr_return_amt) AS return_amount,
        COUNT(*) AS return_cnt
    FROM tpcds.web_returns wr
    JOIN tpcds.item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE REGEXP_LIKE(i.i_product_name, 'Premium')
      AND i.i_color LIKE '%Red%'
    GROUP BY CONCAT(i.i_brand, '-', i.i_category), t.t_sub_shift
),
full_join AS (
    SELECT
        COALESCE(s.brand_category, r.brand_category) AS brand_category,
        COALESCE(s.sub_shift, r.sub_shift) AS sub_shift,
        s.sales_amount,
        r.return_amount
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
        ON s.brand_category = r.brand_category
       AND s.sub_shift = r.sub_shift
)
SELECT
    brand_category,
    sub_shift,
    SUM(COALESCE(sales_amount, 0)) AS total_sales,
    SUM(COALESCE(return_amount, 0)) AS total_returns,
    SUM(COALESCE(sales_amount, 0)) - SUM(COALESCE(return_amount, 0)) AS net_amount,
    CASE
        WHEN SUM(COALESCE(sales_amount, 0)) - SUM(COALESCE(return_amount, 0)) > 0 THEN 'PROFIT'
        ELSE 'LOSS'
    END AS net_status,
    (SELECT AVG(ss_ext_sales_price) FROM tpcds.store_sales) AS avg_sales_price
FROM full_join
GROUP BY ROLLUP (brand_category, sub_shift)
ORDER BY brand_category NULLS LAST, sub_shift NULLS LAST, net_amount DESC
LIMIT 100
