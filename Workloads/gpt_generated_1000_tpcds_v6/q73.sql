WITH
    agg_store_sales AS (
        SELECT
            ss.ss_store_sk,
            ss.ss_sold_date_sk AS d_date_sk,
            SUM(ss.ss_net_profit) AS total_net_profit,
            SUM(ss.ss_quantity) AS total_quantity
        FROM store_sales ss
        GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
    ),
    agg_catalog_sales AS (
        SELECT
            cs.cs_warehouse_sk,
            cs.cs_sold_date_sk AS d_date_sk,
            SUM(cs.cs_net_paid) AS total_cs_net_paid
        FROM catalog_sales cs
        GROUP BY cs.cs_warehouse_sk, cs.cs_sold_date_sk
    ),
    distinct_items AS (
        SELECT DISTINCT i_item_sk, i_category
        FROM item
    )
SELECT
    d.d_year,
    s.s_store_name,
    s.s_state,
    cc.cc_name AS call_center_name,
    w.w_warehouse_name,
    di.i_category,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sagg.total_net_profit,
    sagg.total_quantity,
    cas.total_cs_net_paid,
    sr.sr_return_quantity,
    cr.cr_return_quantity,
    wr.wr_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY sagg.total_net_profit DESC) AS profit_rank
FROM date_dim d
JOIN agg_store_sales sagg
    ON d.d_date_sk = sagg.d_date_sk
JOIN store s
    ON s.s_store_sk = sagg.ss_store_sk
LEFT JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
LEFT JOIN agg_catalog_sales cas
    ON d.d_date_sk = cas.d_date_sk
LEFT JOIN warehouse w
    ON w.w_warehouse_sk = cas.cs_warehouse_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN item i
    ON i.i_item_sk = cr.cr_item_sk
LEFT JOIN distinct_items di
    ON di.i_item_sk = i.i_item_sk
LEFT JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN customer c
    ON c.c_first_sales_date_sk = d.d_date_sk
LEFT JOIN customer_address ca
    ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN customer_demographics cd
    ON cd.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN household_demographics hd
    ON hd.hd_demo_sk = c.c_current_hdemo_sk
LEFT JOIN income_band ib
    ON ib.ib_income_band_sk = hd.hd_income_band_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND i.i_brand = 'Brand#23'
  AND cc.cc_name IS NOT NULL
ORDER BY sagg.total_net_profit DESC, profit_rank
LIMIT 100
