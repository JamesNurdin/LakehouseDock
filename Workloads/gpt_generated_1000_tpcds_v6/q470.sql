WITH sales_inventory AS (
    SELECT
        d.d_year,
        d.d_date,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        ss.ss_ext_tax,
        i.inv_quantity_on_hand,
        CASE WHEN i.inv_quantity_on_hand > 500 THEN 'High' ELSE 'Low' END AS inventory_status
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND d.d_holiday = 'N'
      AND d.d_current_quarter = 'Y'
      AND i.inv_quantity_on_hand >= 200
      AND i.inv_item_sk IN (101432, 101438, 101446)
      AND ss.ss_ext_tax > 10.00
      AND ss.ss_sales_price > 0.00
)
SELECT
    si.d_year,
    si.d_date,
    si.ss_item_sk,
    SUM(si.ss_ext_sales_price) AS total_sales,
    SUM(si.ss_quantity) AS total_units,
    COUNT(DISTINCT si.ss_customer_sk) AS distinct_customers,
    MAX(CASE WHEN si.inventory_status = 'High' THEN 1 ELSE 0 END) AS has_high_inventory,
    RANK() OVER (PARTITION BY si.d_year ORDER BY SUM(si.ss_ext_sales_price) DESC) AS sales_rank
FROM sales_inventory si
GROUP BY
    si.d_year,
    si.d_date,
    si.ss_item_sk
HAVING SUM(si.ss_ext_sales_price) > 1000
ORDER BY sales_rank ASC, total_sales DESC
LIMIT 100
