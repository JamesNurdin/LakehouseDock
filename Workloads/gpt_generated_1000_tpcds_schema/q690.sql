WITH cs_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        hd.hd_buy_potential,
        cc.cc_name,
        cp.cp_department,
        w.w_city AS warehouse_city,
        -- scalar sub‑query to fetch the highest income bound for the household
        (SELECT MAX(ib_upper_bound) FROM income_band ib WHERE ib.ib_income_band_sk = hd.hd_income_band_sk) AS max_income_upper,
        -- lateral sub‑query counting how many warehouses share the same city as the current warehouse
        wc.same_city_warehouse_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS same_city_warehouse_cnt
        FROM warehouse w2
        WHERE w2.w_city = w.w_city
    ) wc
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'F'
      AND hd.hd_buy_potential = '1001-5000'
      AND cc.cc_name LIKE '%Center%'
      AND cp.cp_department = 'Electronics'
      AND w.w_city = 'San Francisco'
),

sr_base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        d.d_year,
        s.s_store_name,
        r.r_reason_desc,
        cd.cd_education_status,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND s.s_manager = 'Joe Johnson'
      AND r.r_reason_desc = 'Damaged'
      AND cd.cd_education_status = 'College'
      AND hd.hd_vehicle_count >= 1
      AND ib.ib_lower_bound >= 20000
),

wr_base AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        d.d_year,
        r.r_reason_desc,
        cd.cd_gender,
        hd.hd_buy_potential
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc = 'Customer Not Satisfied'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '0-500'
),

cs_agg AS (
    SELECT
        d_year,
        COUNT(*) AS cs_cnt,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_net_profit) AS avg_profit,
        MAX(max_income_upper) AS max_income_upper,
        SUM(same_city_warehouse_cnt) AS total_same_city_warehouses
    FROM cs_base
    GROUP BY d_year
),

sr_agg AS (
    SELECT
        d_year,
        COUNT(*) AS sr_cnt,
        SUM(sr_return_amt) AS total_return,
        AVG(sr_net_loss) AS avg_loss,
        MIN(ib_lower_bound) AS min_income_lower
    FROM sr_base
    GROUP BY d_year
),

wr_agg AS (
    SELECT
        d_year,
        COUNT(*) AS wr_cnt,
        SUM(wr_return_amt) AS total_web_return,
        AVG(wr_return_amt) AS avg_web_return_amt
    FROM wr_base
    GROUP BY d_year
),

combined AS (
    SELECT
        cs.d_year,
        cs.cs_cnt,
        sr.sr_cnt,
        wr.wr_cnt,
        cs.total_sales,
        sr.total_return,
        wr.total_web_return,
        cs.avg_profit,
        sr.avg_loss,
        wr.avg_web_return_amt,
        cs.max_income_upper,
        sr.min_income_lower,
        cs.total_same_city_warehouses
    FROM cs_agg cs
    JOIN sr_agg sr ON cs.d_year = sr.d_year
    JOIN wr_agg wr ON cs.d_year = wr.d_year
)
SELECT *
FROM (
    SELECT * FROM combined
    UNION DISTINCT
    SELECT * FROM combined WHERE cs_cnt > 0
) u
INTERSECT
SELECT *
FROM combined
WHERE total_sales > 10000
ORDER BY d_year DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
