WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        d.d_year,
        i.i_brand,
        hd.hd_buy_potential,
        sm.sm_type,
        cp.cp_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = ss.ss_sold_date_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE ss.ss_quantity > 1
      AND d.d_year = 2001
      AND hd.hd_buy_potential = '5001-10000'
),
no_return_sales AS (
    SELECT f.*
    FROM filtered_sales f
    WHERE NOT EXISTS (
        SELECT 1 FROM store_returns sr
        WHERE sr.sr_ticket_number = f.ss_ticket_number
    )
),
brand_agg AS (
    SELECT
        nr.i_brand,
        AVG(nr.ss_net_paid) AS avg_net_paid,
        COUNT(*) AS sales_cnt
    FROM no_return_sales nr
    GROUP BY nr.i_brand
),
ticket_without_return AS (
    SELECT ss_ticket_number
    FROM store_sales
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
),
brand_without_return AS (
    SELECT DISTINCT i.i_brand
    FROM store_sales ss
    JOIN ticket_without_return twr ON ss.ss_ticket_number = twr.ss_ticket_number
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
final AS (
    SELECT
        ba.i_brand,
        ba.avg_net_paid,
        ba.sales_cnt,
        (SELECT AVG(cs.cs_net_paid) FROM catalog_sales cs) AS avg_catalog_net_paid,
        t.brand_day_total
    FROM brand_agg ba
    CROSS JOIN LATERAL (
        SELECT SUM(ss2.ss_net_paid) AS brand_day_total
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
        WHERE i2.i_brand = ba.i_brand
          AND d2.d_year = 2001
    ) t
    WHERE ba.avg_net_paid > (SELECT AVG(cs.cs_net_paid) FROM catalog_sales cs)
)
SELECT
    f.i_brand,
    f.avg_net_paid,
    f.sales_cnt,
    f.avg_catalog_net_paid,
    f.brand_day_total
FROM final f
WHERE f.i_brand IN (SELECT i_brand FROM brand_without_return)
ORDER BY f.avg_net_paid DESC
LIMIT 50
