WITH
    sales_agg AS (
        SELECT
            cs.cs_warehouse_sk,
            cs.cs_promo_sk,
            d.d_year,
            hd.hd_income_band_sk,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            SUM(cs.cs_net_profit) AS total_profit,
            SUM(cs.cs_quantity) AS total_quantity
        FROM catalog_sales cs
        JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        GROUP BY
            cs.cs_warehouse_sk,
            cs.cs_promo_sk,
            d.d_year,
            hd.hd_income_band_sk
    ),
    returns_agg AS (
        SELECT
            d.d_year,
            hd.hd_income_band_sk,
            SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
            SUM(sr.sr_net_loss) AS total_net_loss,
            COUNT(*) AS return_cnt
        FROM store_returns sr
        JOIN date_dim d
            ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN household_demographics hd
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
        GROUP BY
            d.d_year,
            hd.hd_income_band_sk
    ),
    common_warehouses AS (
        SELECT cs.cs_warehouse_sk
        FROM catalog_sales cs
        INTERSECT
        SELECT w.w_warehouse_sk
        FROM warehouse w
    )
SELECT
    w.w_warehouse_name,
    w.w_gmt_offset,
    p.p_promo_name,
    sa.d_year,
    sa.hd_income_band_sk,
    sa.total_sales,
    ra.total_return_amt,
    CASE
        WHEN sa.total_sales = 0 THEN 'No Sales'
        WHEN sa.total_profit / NULLIF(sa.total_sales, 0) > 0.2 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    (
        SELECT SUM(w2.w_warehouse_sq_ft)
        FROM warehouse w2
        WHERE w2.w_state = w.w_state
    ) AS state_total_sq_ft
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.d_year = ra.d_year
   AND sa.hd_income_band_sk = ra.hd_income_band_sk
LEFT JOIN warehouse w
    ON sa.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion p
    ON sa.cs_promo_sk = p.p_promo_sk
LEFT JOIN common_warehouses cw
    ON sa.cs_warehouse_sk = cw.cs_warehouse_sk
WHERE
    (sa.d_year BETWEEN 2000 AND 2002 OR ra.d_year BETWEEN 2000 AND 2002)
    AND (sa.hd_income_band_sk IN (2, 3, 7) OR ra.hd_income_band_sk IN (2, 3, 7))
    AND w.w_gmt_offset = -5.00
    AND p.p_discount_active = 'Y'
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = sa.cs_promo_sk
          AND p2.p_purpose = 'Clearance'
    )
ORDER BY
    profit_category ASC,
    total_sales DESC
LIMIT 100
