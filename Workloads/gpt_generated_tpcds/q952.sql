WITH sales_agg AS (
    SELECT
        cc.cc_name,
        d.d_year,
        d.d_moy,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
    GROUP BY cc.cc_name, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        cc.cc_name,
        d.d_year,
        d.d_moy,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
    GROUP BY cc.cc_name, d.d_year, d.d_moy
)
SELECT
    s.cc_name,
    s.d_year,
    s.d_moy,
    s.distinct_customers,
    s.total_sales,
    s.total_profit,
    s.avg_discount,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cc_name = r.cc_name
    AND s.d_year = r.d_year
    AND s.d_moy = r.d_moy
ORDER BY s.total_sales DESC
LIMIT 100
