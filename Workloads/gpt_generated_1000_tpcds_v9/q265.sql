WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_paid) AS total_store_sales,
        SUM(ss_quantity) AS total_store_qty
    FROM store_sales
    GROUP BY ss_item_sk, ss_store_sk, ss_sold_date_sk
),
cs_agg AS (
    SELECT
        cs_item_sk,
        cs_bill_customer_sk,
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_promo_sk,
        cs_bill_addr_sk,
        cs_bill_cdemo_sk,
        SUM(cs_net_paid) AS total_catalog_sales,
        COUNT(*) AS catalog_order_cnt
    FROM catalog_sales
    GROUP BY cs_item_sk, cs_bill_customer_sk, cs_sold_date_sk, cs_sold_time_sk,
             cs_ship_mode_sk, cs_warehouse_sk, cs_promo_sk, cs_bill_addr_sk, cs_bill_cdemo_sk
),
store_returns_agg AS (
    SELECT
        sr_item_sk,
        sr_store_sk,
        sr_reason_sk,
        SUM(sr_net_loss) AS total_store_return_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns
    GROUP BY sr_item_sk, sr_store_sk, sr_reason_sk
),
web_returns_agg AS (
    SELECT
        wr_item_sk,
        wr_reason_sk,
        SUM(wr_net_loss) AS total_web_return_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns
    GROUP BY wr_item_sk, wr_reason_sk
),
avg_store_sales AS (
    SELECT AVG(total_store_sales) AS avg_sales FROM ss_agg
)
SELECT
    dss.d_year,
    dss.d_date,
    i.i_category,
    i.i_brand,
    s.s_store_name,
    ss.total_store_sales,
    ss.total_store_qty,
    cs.total_catalog_sales,
    cs.catalog_order_cnt,
    w.w_warehouse_name,
    sm.sm_type AS ship_mode_type,
    p.p_promo_name,
    ca.ca_city,
    cd.cd_gender,
    sr.total_store_return_loss,
    sr.store_return_cnt,
    r.r_reason_desc AS store_return_reason,
    wr.total_web_return_loss,
    wr.web_return_cnt,
    rp.r_reason_desc AS web_return_reason,
    CASE
        WHEN ss.total_store_sales > (SELECT avg_sales FROM avg_store_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_performance,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ss.total_store_sales DESC) AS sales_rank_in_category,
    (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_item_sk = i.i_item_sk) AS web_return_count_for_item,
    CASE WHEN i.i_item_sk IN (SELECT DISTINCT wr_item_sk FROM web_returns) THEN 'Has Web Return' ELSE 'No Web Return' END AS web_return_flag
FROM ss_agg ss
JOIN date_dim dss ON ss.ss_sold_date_sk = dss.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN cs_agg cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_sold_date_sk = dss.d_date_sk
LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
LEFT JOIN store_returns_agg sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_store_sk = ss.ss_store_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns_agg wr ON wr.wr_item_sk = ss.ss_item_sk
LEFT JOIN reason rp ON wr.wr_reason_sk = rp.r_reason_sk
LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    dss.d_year = 2002
    AND i.i_category = 'Sports'
    AND w.w_warehouse_sq_ft > 500000
ORDER BY
    ss.total_store_sales DESC,
    dss.d_date
LIMIT 100
