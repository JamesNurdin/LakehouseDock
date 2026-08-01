WITH
    sales_agg AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_bill_hdemo_sk AS hd_demo_sk,
            SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
            AVG(cs.cs_ext_discount_amt) AS avg_discount,
            COUNT(*) AS sales_cnt
        FROM catalog_sales cs
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE cs.cs_net_paid_inc_ship > 1000.00
          AND ib.ib_lower_bound >= 30000
          AND cs.cs_quantity BETWEEN 1 AND 10
        GROUP BY cs.cs_item_sk, cs.cs_bill_hdemo_sk
    ),
    items_without_returns AS (
        SELECT i.i_item_sk
        FROM item i
        EXCEPT
        SELECT sr.sr_item_sk
        FROM store_returns sr
    ),
    returns_join AS (
        SELECT
            hd.hd_demo_sk,
            hd.hd_vehicle_count,
            sr.sr_item_sk,
            sr.sr_return_amt
        FROM store_returns sr
        RIGHT OUTER JOIN household_demographics hd
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
    ),
    base_data AS (
        SELECT
            i.i_brand,
            ib.ib_income_band_sk,
            sa.total_net_paid,
            sa.avg_discount,
            i.i_item_id,
            hd.hd_vehicle_count,
            rj.sr_return_amt
        FROM sales_agg sa
        JOIN item i ON sa.cs_item_sk = i.i_item_sk
        JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
        JOIN household_demographics hd ON sa.hd_demo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN returns_join rj
            ON i.i_item_sk = rj.sr_item_sk
           AND hd.hd_demo_sk = rj.hd_demo_sk
        WHERE i.i_current_price > 20.00
          AND inv.inv_quantity_on_hand > 0
          AND hd.hd_vehicle_count > (
                SELECT MIN(hd2.hd_vehicle_count)
                FROM household_demographics hd2
                WHERE hd2.hd_dep_count > 5
            )
          AND i.i_item_sk IN (SELECT i_item_sk FROM items_without_returns)
    ),
    agg_data AS (
        SELECT
            i_brand,
            ib_income_band_sk,
            SUM(total_net_paid) AS sum_net_paid,
            AVG(avg_discount) AS avg_discount,
            COUNT(DISTINCT i_item_id) AS distinct_items,
            MAX(hd_vehicle_count) AS max_vehicle_cnt
        FROM base_data
        GROUP BY GROUPING SETS (
            (i_brand, ib_income_band_sk),
            (i_brand),
            (ib_income_band_sk),
            ()
        )
    )
SELECT
    i_brand,
    ib_income_band_sk,
    sum_net_paid,
    avg_discount,
    distinct_items,
    max_vehicle_cnt,
    ROW_NUMBER() OVER (PARTITION BY ib_income_band_sk ORDER BY sum_net_paid DESC) AS rn
FROM agg_data
ORDER BY sum_net_paid DESC
LIMIT 100
