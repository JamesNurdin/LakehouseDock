WITH combined AS (
    -- Sales aggregated by customer credit rating
    SELECT
        cd.cd_credit_rating AS credit_rating,
        SUM(ss.ss_ext_sales_price) AS total_amount
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_list_price > 50
    GROUP BY cd.cd_credit_rating

    UNION ALL

    -- Warehouse inventory value (full outer join keeps warehouses without inventory and vice‑versa)
    SELECT
        'Warehouse' AS credit_rating,
        SUM(COALESCE(i.inv_quantity_on_hand, 0) * 10) AS total_amount
    FROM warehouse w
    FULL OUTER JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
)
SELECT
    credit_rating,
    total_amount,
    ROW_NUMBER() OVER (ORDER BY total_amount DESC) AS rn
FROM combined
ORDER BY total_amount DESC
OFFSET 0 LIMIT 100
