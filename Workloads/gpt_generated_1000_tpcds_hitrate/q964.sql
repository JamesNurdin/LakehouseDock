WITH recent_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2001
)
SELECT year,
       metric,
       amount,
       profit_category
FROM (
    -- Sales data
    SELECT
        d.d_year AS year,
        'sales_net_paid' AS metric,
        SUM(ss.ss_net_paid) AS amount,
        CASE
            WHEN SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_net_paid), 0) > 0.20 THEN 'High'
            ELSE 'Low'
        END AS profit_category
    FROM store_sales ss
    JOIN recent_dates d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND ss.ss_cdemo_sk IN (
            SELECT cd2.cd_demo_sk
            FROM customer_demographics cd2
            WHERE cd2.cd_credit_rating = 'Excellent'
        )
    GROUP BY d.d_year

    UNION ALL

    -- Inventory data
    SELECT
        d.d_year AS year,
        'inventory_quantity' AS metric,
        CAST(SUM(i.inv_quantity_on_hand) AS decimal(15,2)) AS amount,
        CAST(NULL AS varchar) AS profit_category
    FROM inventory i
    JOIN recent_dates d ON i.inv_date_sk = d.d_date_sk
    WHERE i.inv_quantity_on_hand > (
            SELECT AVG(inv_quantity_on_hand)
            FROM inventory
        )
    GROUP BY d.d_year
) AS combined
ORDER BY year, metric
