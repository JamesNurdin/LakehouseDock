WITH
sales_agg AS (
    SELECT
        d_sold.d_year AS year,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        0.0 AS return_amount,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        'sales' AS src
    FROM
        catalog_sales cs
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d_sold.d_year BETWEEN 2001 AND 2002
    GROUP BY d_sold.d_year, i.i_category
),
returns_agg AS (
    SELECT
        d_ret.d_year AS year,
        i.i_category AS category,
        0.0 AS sales_amount,
        SUM(cr.cr_return_amount) AS return_amount,
        CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS profit_flag,
        'returns' AS src
    FROM
        catalog_returns cr
        JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
        JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d_ret.d_year BETWEEN 2001 AND 2002
    GROUP BY d_ret.d_year, i.i_category
),
combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
),
final_agg AS (
    SELECT
        year,
        category,
        SUM(sales_amount) AS total_sales,
        SUM(return_amount) AS total_returns,
        CASE WHEN SUM(sales_amount) - SUM(return_amount) > 0 THEN 'NetPositive' ELSE 'NetNegative' END AS net_status,
        SUM(sales_amount) - SUM(return_amount) AS net_amount,
        RANK() OVER (PARTITION BY year ORDER BY SUM(sales_amount) - SUM(return_amount) DESC) AS sales_rank,
        SUM(SUM(sales_amount) - SUM(return_amount)) OVER (PARTITION BY year ORDER BY category
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net
    FROM combined
    GROUP BY year, category
)
SELECT
    year,
    category,
    total_sales,
    total_returns,
    net_amount,
    net_status,
    sales_rank,
    cumulative_net
FROM final_agg
ORDER BY year DESC, net_amount DESC
LIMIT 100
