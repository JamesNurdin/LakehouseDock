WITH unified_sales AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_item_sk AS item_sk,
        ss_ext_sales_price AS sales,
        ss_net_profit AS profit,
        ss_customer_sk AS cust_sk
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        cs_ext_sales_price,
        cs_net_profit,
        cs_bill_customer_sk
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_ext_sales_price,
        ws_net_profit,
        ws_bill_customer_sk
    FROM web_sales
), promo_agg AS (
    SELECT p_item_sk, SUM(p_cost) AS promo_cost
    FROM promotion
    GROUP BY p_item_sk
)
SELECT
    d.d_year,
    i.i_category,
    COUNT(DISTINCT us.cust_sk) AS distinct_customers,
    SUM(us.sales) AS total_sales,
    SUM(us.profit) AS total_profit,
    AVG(us.sales) AS avg_sales_per_order,
    COALESCE(SUM(pr.promo_cost), 0) AS total_promo_cost
FROM unified_sales us
JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
LEFT JOIN promo_agg pr ON us.item_sk = pr.p_item_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, total_sales DESC
LIMIT 100
