WITH sales_agg AS (
    SELECT
        cp.cp_department AS department,
        i.i_brand AS brand,
        d_sold.d_quarter_name AS quarter,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs.cs_sold_date_sk) AS distinct_sales_days,
        SUM(cs.cs_quantity) AS total_quantity,
        MIN(cs.cs_ext_sales_price) AS min_sales,
        MAX(cs.cs_ext_sales_price) AS max_sales,
        CASE WHEN SUM(cs.cs_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr ON cs.cs_item_sk = wr.wr_item_sk AND cs.cs_sold_date_sk = wr.wr_returned_date_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d_sold.d_year = 2001
      AND cp.cp_type = 'monthly'
      AND i.i_brand = 'Brand#12'
      AND p.p_channel_demo = 'N'
      AND t.t_hour BETWEEN 9 AND 17
      AND hd.hd_income_band_sk BETWEEN 3 AND 5
      AND EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_item_sk = cs.cs_item_sk
            AND wr2.wr_returned_date_sk = cs.cs_sold_date_sk
      )
    GROUP BY cp.cp_department, i.i_brand, d_sold.d_quarter_name
)
SELECT
    department,
    brand,
    quarter,
    total_sales,
    avg_profit,
    distinct_sales_days,
    total_quantity,
    min_sales,
    max_sales,
    profit_category,
    SUM(total_sales) OVER (PARTITION BY department) AS department_total_sales,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY total_sales DESC) AS department_rank,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper_bound
FROM sales_agg
ORDER BY total_sales DESC, department
