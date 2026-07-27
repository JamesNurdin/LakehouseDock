WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_catalog_page_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_qty,
        AVG(cs.cs_coupon_amt) AS avg_coupon_amt
    FROM catalog_sales cs
    WHERE
        cs.cs_ext_tax > 20.00
        AND cs.cs_ext_discount_amt BETWEEN 0 AND 500
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
        AND cs.cs_ship_hdemo_sk IN (2685, 4375, 2319)
        AND cs.cs_coupon_amt > 50.00
        AND cs.cs_list_price > 0
    GROUP BY cs.cs_item_sk, cs.cs_bill_customer_sk, cs.cs_catalog_page_sk
)
SELECT
    c.c_customer_id,
    i.i_item_id,
    cp.cp_department,
    sa.total_sales,
    sa.total_qty,
    CASE
        WHEN sa.total_sales > (SELECT AVG(total_sales) FROM sales_agg) THEN 'High'
        ELSE 'Low'
    END AS sales_category,
    COUNT(sr.sr_ticket_number) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM sales_agg sa
JOIN catalog_page cp ON cp.cp_catalog_page_sk = sa.cs_catalog_page_sk
JOIN item i ON i.i_item_sk = sa.cs_item_sk
JOIN customer c ON c.c_customer_sk = sa.cs_bill_customer_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_customer_sk = c.c_customer_sk
WHERE
    i.i_class_id IN (4, 7, 10)
    AND i.i_color = 'Unknown'
    AND c.c_birth_year BETWEEN 1950 AND 1990
    AND cp.cp_type = 'Standard'
    AND sr.sr_store_sk IN (640, 760, 826)
    AND sr.sr_return_quantity > 0
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_return_amt > 100
    )
GROUP BY
    c.c_customer_id,
    i.i_item_id,
    cp.cp_department,
    sa.total_sales,
    sa.total_qty
ORDER BY
    sa.total_sales DESC,
    return_count DESC
LIMIT 100
