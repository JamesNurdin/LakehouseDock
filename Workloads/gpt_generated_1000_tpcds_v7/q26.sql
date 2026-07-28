WITH filtered_sales AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cp.cp_description,
        cc.cc_manager,
        cc.cc_call_center_id,
        d_sold.d_year
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2002
      AND regexp_like(cp.cp_description, '(?i)building')
      AND cc.cc_manager LIKE '%Jack%'
),
aggregated AS (
    SELECT
        fs.cc_call_center_id,
        fs.cc_manager,
        SUM(fs.cs_ext_sales_price) AS total_sales,
        AVG(fs.cs_ext_discount_amt) AS avg_discount,
        substring(fs.cc_manager, 1, 3) AS manager_prefix,
        concat(fs.cc_manager, ' - ', fs.cc_call_center_id) AS manager_center
    FROM filtered_sales fs
    WHERE EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr
        JOIN tpcds.date_dim d_ret
            ON sr.sr_returned_date_sk = d_ret.d_date_sk
        WHERE d_ret.d_year = fs.d_year
          AND sr.sr_return_amt > 500
    )
    GROUP BY
        fs.cc_call_center_id,
        fs.cc_manager,
        substring(fs.cc_manager, 1, 3),
        concat(fs.cc_manager, ' - ', fs.cc_call_center_id)
)
SELECT
    a.cc_call_center_id,
    a.cc_manager,
    a.manager_prefix,
    a.manager_center,
    a.total_sales,
    a.avg_discount,
    (SELECT AVG(cs3.cs_ext_discount_amt) FROM tpcds.catalog_sales cs3) AS overall_avg_discount,
    ROW_NUMBER() OVER (ORDER BY a.total_sales DESC) AS sales_rank
FROM aggregated a
ORDER BY a.total_sales DESC
LIMIT 100
