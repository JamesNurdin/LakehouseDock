WITH sales_returns AS (
    SELECT
        i.i_category AS category,
        cd.cd_credit_rating AS credit_rating,
        CONCAT(i.i_brand, ' ', i.i_color) AS brand_color,
        REGEXP_EXTRACT(i.i_item_desc, '([A-Z]{2}[0-9]{3})', 1) AS item_code,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders,
        CASE
            WHEN cd.cd_credit_rating = 'High Risk' THEN 'Risky'
            WHEN cd.cd_credit_rating = 'Low Risk' THEN 'LowRisk'
            ELSE 'Other'
        END AS risk_category,
        (SUM(cs.cs_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_sales_after_returns
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE i.i_color LIKE 'p%'
      AND i.i_container LIKE '%BOX%'
      AND REGEXP_LIKE(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
      AND c.c_birth_country IN ('RWANDA', 'HUNGARY')
    GROUP BY
        i.i_category,
        cd.cd_credit_rating,
        CONCAT(i.i_brand, ' ', i.i_color),
        REGEXP_EXTRACT(i.i_item_desc, '([A-Z]{2}[0-9]{3})', 1)
    HAVING SUM(cs.cs_ext_sales_price) > 50000
)
SELECT
    category,
    credit_rating,
    brand_color,
    item_code,
    total_sales_amount,
    total_profit,
    distinct_orders,
    total_return_amount,
    total_return_loss,
    distinct_return_orders,
    risk_category,
    net_sales_after_returns
FROM sales_returns
ORDER BY total_sales_amount DESC
LIMIT 100
