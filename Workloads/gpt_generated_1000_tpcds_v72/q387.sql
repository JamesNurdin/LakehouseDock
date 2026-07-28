WITH joined_data AS (
    SELECT
        s.s_store_name                         AS s_store_name,
        d.d_year                               AS d_year,
        cs.cs_ext_sales_price                  AS cs_ext_sales_price,
        cr.cr_return_amount                    AS cr_return_amount,
        cs.cs_net_profit                       AS cs_net_profit
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
       AND cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
      AND t.t_meal_time = 'dinner'
),
agg_data AS (
    SELECT
        s_store_name,
        d_year,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cr_return_amount)   AS total_returns,
        SUM(cs_net_profit)      AS total_profit,
        CASE WHEN SUM(cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM joined_data
    GROUP BY s_store_name, d_year
)
SELECT
    s_store_name,
    d_year,
    total_sales,
    total_returns,
    total_profit,
    profit_category,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg_data
ORDER BY total_profit DESC
LIMIT 100
