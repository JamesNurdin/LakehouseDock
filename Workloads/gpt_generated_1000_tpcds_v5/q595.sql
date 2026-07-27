WITH cs_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_item_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1000
)
SELECT
    d.d_year,
    s.s_store_name,
    cc.cc_name,
    cp.cp_type,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    csb.cs_ext_sales_price,
    csb.cs_net_profit,
    CASE WHEN csb.cs_net_profit > 500 THEN 'High' ELSE 'Low' END AS profit_category,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY csb.cs_ext_sales_price DESC) AS sales_rank,
    SUM(csb.cs_ext_sales_price) OVER (
        PARTITION BY s.s_store_name
        ORDER BY csb.cs_ext_sales_price DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales
FROM cs_base csb
JOIN date_dim d
    ON csb.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON csb.cs_sold_time_sk = t.t_time_sk
JOIN call_center cc
    ON csb.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON csb.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN household_demographics hd
    ON csb.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim t2
    ON ss.ss_sold_time_sk = t2.t_time_sk
WHERE
    d.d_year = 2001
    AND cc.cc_state = 'CA'
    AND s.s_state = 'CA'
    AND ib.ib_lower_bound >= 50000
ORDER BY cumulative_sales DESC
LIMIT 100
