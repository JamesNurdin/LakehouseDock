WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        d_s.d_year,
        i.i_category,
        sm.sm_type,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS quantity_type,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY cs.cs_ext_sales_price DESC) AS rn_category_sales
    FROM catalog_sales cs
    JOIN date_dim d_s ON cs.cs_sold_date_sk = d_s.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d_s.d_fy_quarter_seq IN (1, 2, 3, 4)
      AND d_s.d_year = 2001
      AND i.i_brand_id = 123
      AND sm.sm_type = 'AIR'
)
SELECT * FROM (
    SELECT
        'SALES' AS source,
        ca.d_year,
        ca.i_category,
        ca.sm_type,
        ca.quantity_type,
        ca.cs_ext_sales_price,
        ca.cs_net_profit,
        ca.rn_category_sales,
        CAST(NULL AS decimal(7,2)) AS sr_return_amt,
        CAST(NULL AS decimal(7,2)) AS sr_net_loss,
        CAST(NULL AS varchar) AS store_name,
        CAST(NULL AS integer) AS employee_count,
        DENSE_RANK() OVER (ORDER BY ca.cs_ext_sales_price DESC) AS rank_score
    FROM sales_agg ca
    WHERE ca.rn_category_sales <= 10

    UNION ALL

    SELECT
        'RETURNS' AS source,
        d_r.d_year,
        i_r.i_category,
        CAST(NULL AS varchar) AS sm_type,
        CASE WHEN sr.sr_return_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS quantity_type,
        CAST(NULL AS decimal(7,2)) AS cs_ext_sales_price,
        CAST(NULL AS decimal(7,2)) AS cs_net_profit,
        CAST(NULL AS bigint) AS rn_category_sales,
        sr.sr_return_amt,
        sr.sr_net_loss,
        s.s_store_name,
        s.s_number_employees,
        RANK() OVER (ORDER BY sr.sr_return_amt DESC) AS rank_score
    FROM store_returns sr
    JOIN date_dim d_r ON sr.sr_returned_date_sk = d_r.d_date_sk
    JOIN item i_r ON sr.sr_item_sk = i_r.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d_r.d_fy_quarter_seq = 2
      AND d_r.d_year = 2001
      AND i_r.i_class_id = 5
      AND s.s_number_employees > 200
) combined
ORDER BY source,
         rank_score ASC NULLS LAST
LIMIT 100
