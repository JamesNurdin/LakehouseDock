WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_item_sk,
        i.i_item_desc,
        i.i_product_name,
        ca.ca_state,
        t.t_hour,
        t.t_minute
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '(?i)USB|HDMI')
      AND ca.ca_state LIKE 'C%'
),
avg_return AS (
    SELECT AVG(cr2.cr_return_amount) AS avg_amt
    FROM catalog_returns cr2
)
SELECT description,
       metric_total,
       orders,
       rank,
       category
FROM (
    -- Returns side
    SELECT
        r.r_reason_desc AS description,
        SUM(cr.cr_return_amount) AS metric_total,
        COUNT(DISTINCT cr.cr_order_number) AS orders,
        ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS rank,
        'Return' AS category
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)size|color')
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs
          WHERE cs.cs_order_number = cr.cr_order_number
            AND cs.cs_ext_sales_price > 500
      )
    GROUP BY r.r_reason_desc
    HAVING SUM(cr.cr_return_amount) > (SELECT avg_amt FROM avg_return)

    UNION ALL

    -- Sales side
    SELECT
        SUBSTRING(i.i_product_name, 1, 10) AS description,
        SUM(fs.cs_ext_sales_price) AS metric_total,
        COUNT(DISTINCT fs.cs_order_number) AS orders,
        ROW_NUMBER() OVER (ORDER BY SUM(fs.cs_ext_sales_price) DESC) AS rank,
        'Sale' AS category
    FROM filtered_sales fs
    JOIN item i ON fs.cs_item_sk = i.i_item_sk
    WHERE i.i_product_name LIKE '%Pro%'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_item_sk = i.i_item_sk
            AND cr.cr_return_amount > 100
      )
    GROUP BY SUBSTRING(i.i_product_name, 1, 10)
) combined
ORDER BY metric_total DESC
LIMIT 20
