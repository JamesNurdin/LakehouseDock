WITH sales_agg AS (
    SELECT cs_item_sk,
           cs_promo_sk,
           SUM(cs_net_paid) AS total_sales,
           SUM(cs_quantity) AS total_qty
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    GROUP BY cs_item_sk, cs_promo_sk
),
filtered_stores AS (
    SELECT s_store_sk
    FROM store
    WHERE s_number_employees > 50
    EXCEPT
    SELECT sr_store_sk
    FROM store_returns
    WHERE sr_net_loss > 1000
)
SELECT
    fs.s_store_sk,
    s.s_store_name,
    d_sold.d_year,
    p.p_promo_name,
    SUM(sa.total_sales)            AS sales_amount,
    SUM(sr.sr_net_loss)            AS return_loss,
    COUNT(DISTINCT i.i_item_id)    AS distinct_items,
    COUNT(DISTINCT sm.sm_ship_mode_id) AS ship_modes_used
FROM filtered_stores fs
JOIN store s ON s.s_store_sk = fs.s_store_sk
JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN sales_agg sa ON sa.cs_item_sk = i.i_item_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
                         AND cs.cs_promo_sk = sa.cs_promo_sk
JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end   ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_cr_return ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE d_sold.d_year = 2001
GROUP BY CUBE (fs.s_store_sk, s.s_store_name, d_sold.d_year, p.p_promo_name)
LIMIT 100
