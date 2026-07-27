WITH sales_agg AS (
    SELECT
        cp.cp_department AS department,
        cp.cp_catalog_page_number AS catalog_page_number,
        w.w_state AS state,
        cs.cs_bill_addr_sk AS bill_address_sk,
        cs.cs_bill_cdemo_sk AS bill_demo_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        CASE
            WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH'
            WHEN SUM(cs.cs_net_profit) BETWEEN 50000 AND 100000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cp.cp_department IN ('Electronics', 'Clothing', 'Home')
      AND w.w_state = 'CA'
      AND p.p_cost > 500
      AND p.p_channel_event = 'N'
      AND ca.ca_location_type = 'single family'
      AND cd.cd_gender = 'M'
    GROUP BY cp.cp_department, cp.cp_catalog_page_number, w.w_state, cs.cs_bill_addr_sk, cs.cs_bill_cdemo_sk
    HAVING SUM(cs.cs_net_profit) > 0
)
SELECT
    department,
    profit_category,
    AVG(total_net_profit) AS avg_profit,
    SUM(total_sales) AS sum_sales,
    SUM(total_return_amount) AS sum_returns,
    COUNT(*) AS page_count
FROM sales_agg sa
WHERE EXISTS (
    SELECT 1
    FROM customer_address ca2
    WHERE ca2.ca_address_sk = sa.bill_address_sk
      AND ca2.ca_zip LIKE '9%'
)
GROUP BY department, profit_category
ORDER BY avg_profit DESC
LIMIT 100
