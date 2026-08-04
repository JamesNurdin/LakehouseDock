WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_list_price
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 5000.00
      AND cs.cs_quantity >= 2
      AND cs.cs_list_price BETWEEN 100 AND 200
      AND cs.cs_sold_date_sk BETWEEN 2450995 AND 2451180
)
SELECT
    cp.cp_department,
    hd_bill.hd_buy_potential,
    COUNT(*) AS order_count,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    AVG(fs.cs_net_profit) AS avg_profit,
    MIN(fs.cs_quantity) AS min_qty,
    MAX(fs.cs_quantity) AS max_qty,
    (SELECT AVG(cs_list_price) FROM catalog_sales) AS global_avg_list_price
FROM filtered_sales fs
JOIN catalog_page cp
    ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN household_demographics hd_bill
    ON fs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
WHERE hd_bill.hd_demo_sk IN (
    SELECT cs_bill_hdemo_sk FROM catalog_sales WHERE cs_ext_discount_amt > 1000
    INTERSECT
    SELECT cs_ship_hdemo_sk FROM catalog_sales WHERE cs_ext_discount_amt > 1000
)
GROUP BY cp.cp_department, hd_bill.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
