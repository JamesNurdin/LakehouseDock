WITH sales_with_demo AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        i.i_category,
        i.i_brand,
        i.i_size,
        i.i_rec_start_date,
        CASE WHEN wp.wp_web_page_sk IS NOT NULL THEN 1 ELSE 0 END AS web_engaged_flag,
        CASE WHEN cp.cp_type = 'Promotion' THEN 1 ELSE 0 END AS promotion_flag,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        td.t_sub_shift
    FROM catalog_sales cs
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE i.i_size = 'large'
      AND i.i_brand IN ('exportiamalg #1', 'edu packbrand #4')
      AND ib.ib_lower_bound >= 100000
      AND td.t_sub_shift = 'morning'
      AND i.i_rec_start_date <= DATE '2022-01-01'
),
aggregated AS (
    SELECT
        i_category,
        web_engaged_flag,
        promotion_flag,
        COUNT(*) AS total_sales,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit,
        AVG(cs_net_profit) AS avg_net_profit
    FROM sales_with_demo
    GROUP BY i_category, web_engaged_flag, promotion_flag
    HAVING COUNT(*) >= 10
)
SELECT
    a.i_category,
    a.promotion_flag,
    a.web_engaged_flag,
    a.total_sales,
    a.total_quantity,
    a.total_net_profit,
    a.avg_net_profit,
    a.avg_net_profit - AVG(CASE WHEN a.web_engaged_flag = 0 THEN a.avg_net_profit END) OVER (PARTITION BY a.i_category, a.promotion_flag) AS profit_diff_vs_non_web
FROM aggregated a
ORDER BY a.i_category, a.promotion_flag DESC, a.web_engaged_flag DESC
