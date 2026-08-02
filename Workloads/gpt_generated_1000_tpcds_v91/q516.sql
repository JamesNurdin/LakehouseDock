WITH non_returned_orders AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    EXCEPT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
),
sales_base AS (
    SELECT cs.*
    FROM catalog_sales cs
    JOIN non_returned_orders nr ON cs.cs_order_number = nr.cs_order_number
)
SELECT
    cp.cp_catalog_page_number,
    d_sold.d_year,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
FROM sales_base cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN date_dim d_returned
    ON cr.cr_returned_date_sk = d_returned.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
WHERE d_sold.d_year = 2001
GROUP BY cp.cp_catalog_page_number, d_sold.d_year
ORDER BY total_sales DESC
LIMIT 100
