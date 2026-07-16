WITH aggregated AS (
    SELECT
        i.i_category AS category,
        hd.hd_income_band_sk AS income_band,
        SUM(cs.cs_net_paid_inc_ship) AS total_sales,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_returns,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
    WHERE cs.cs_sold_date_sk >= 2450000
    GROUP BY i.i_category, hd.hd_income_band_sk
    HAVING (SUM(cs.cs_net_paid_inc_ship) - COALESCE(SUM(cr.cr_return_amount), 0)) > 1000
)
SELECT
    category,
    income_band,
    total_sales,
    total_returns,
    total_sales - total_returns AS net_revenue,
    total_discount / NULLIF(total_quantity, 0) AS avg_discount,
    total_quantity,
    RANK() OVER (ORDER BY total_sales - total_returns DESC) AS revenue_rank
FROM aggregated
ORDER BY net_revenue DESC
LIMIT 100
