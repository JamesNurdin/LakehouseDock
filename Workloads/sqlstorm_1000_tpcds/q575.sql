SELECT
    agg.d_year,
    agg.i_category,
    agg.i_brand,
    agg.total_sales,
    agg.num_customers,
    agg.avg_sales,
    RANK() OVER (PARTITION BY agg.d_year ORDER BY agg.total_sales DESC) AS sales_rank
FROM (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        SUM(s.sales_amount) AS total_sales,
        COUNT(DISTINCT s.cust_sk) AS num_customers,
        AVG(s.sales_amount) AS avg_sales
    FROM (
        SELECT cs.cs_sold_date_sk AS date_sk, cs.cs_bill_customer_sk AS cust_sk, cs.cs_item_sk AS item_sk, cs.cs_ext_sales_price AS sales_amount
        FROM catalog_sales cs
        UNION ALL
        SELECT ss.ss_sold_date_sk, ss.ss_customer_sk, ss.ss_item_sk, ss.ss_ext_sales_price
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_sold_date_sk, ws.ws_bill_customer_sk, ws.ws_item_sk, ws.ws_ext_sales_price
        FROM web_sales ws
    ) s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, i.i_category, i.i_brand
) agg
ORDER BY agg.total_sales DESC
LIMIT 100
