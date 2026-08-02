WITH sales_agg AS (
    SELECT
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_sold_time_sk,
        cs_bill_cdemo_sk,
        cs_ship_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_ship_hdemo_sk,
        SUM(cs_ext_sales_price) AS total_ext_sales_price,
        SUM(cs_quantity) AS total_quantity,
        AVG(cs_ext_discount_amt) AS avg_discount_amt
    FROM catalog_sales
    WHERE cs_ext_sales_price > 1000
      AND cs_quantity > 0
    GROUP BY
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_sold_time_sk,
        cs_bill_cdemo_sk,
        cs_ship_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_ship_hdemo_sk
),
joined_data AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        td.t_hour,
        td.t_minute,
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        sales_agg.total_ext_sales_price,
        sales_agg.total_quantity,
        CASE
            WHEN sales_agg.total_ext_sales_price > 20000 THEN 'Very High'
            ELSE 'Standard'
        END AS sales_category,
        RANK() OVER (PARTITION BY cc.cc_call_center_id ORDER BY sales_agg.total_ext_sales_price DESC) AS sales_rank,
        la.total_sales_for_center
    FROM sales_agg
    JOIN call_center cc ON sales_agg.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON sales_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON sales_agg.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd_bill ON sales_agg.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON sales_agg.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill ON sales_agg.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON sales_agg.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN LATERAL (
        SELECT SUM(s2.total_ext_sales_price) AS total_sales_for_center
        FROM sales_agg s2
        WHERE s2.cs_call_center_sk = cc.cc_call_center_sk
    ) la ON TRUE
    WHERE cc.cc_state = 'CA'
      AND cp.cp_type = 'A'
      AND td.t_hour BETWEEN 9 AND 20
      AND cd_bill.cd_education_status = 'College'
      AND hd_bill.hd_income_band_sk >= 5
)
SELECT
    cc_call_center_id,
    cc_name,
    cp_catalog_number,
    cp_catalog_page_number,
    t_hour,
    bill_gender,
    ship_gender,
    sales_category,
    sales_rank,
    total_sales_for_center,
    total_ext_sales_price,
    total_quantity
FROM joined_data
WHERE sales_category = 'Very High'

UNION ALL

SELECT
    cc_call_center_id,
    cc_name,
    cp_catalog_number,
    cp_catalog_page_number,
    t_hour,
    bill_gender,
    ship_gender,
    sales_category,
    sales_rank,
    total_sales_for_center,
    total_ext_sales_price,
    total_quantity
FROM joined_data
WHERE sales_category = 'Standard'
  AND total_quantity >= 10

ORDER BY sales_rank
LIMIT 100
