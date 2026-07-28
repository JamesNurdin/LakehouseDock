WITH catalog_sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_wholesale_cost,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_quantity,
        cs.cs_catalog_page_sk,
        cs.cs_bill_hdemo_sk,
        d.d_year,
        d.d_month_seq,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        i.i_brand,
        i.i_category,
        p.p_discount_active,
        w.w_country,
        sm.sm_carrier,
        hd.hd_vehicle_count,
        t.t_hour,
        wp.wp_url,
        ws.web_name
    FROM catalog_sales cs
    INNER JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    -- join auxiliary dimension tables that also use the same date key
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND w.w_country = 'United States'
      AND sm.sm_carrier = 'USPS'
      AND hd.hd_vehicle_count >= 1
),
store_sales_agg AS (
    SELECT
        ss.ss_item_sk,
        AVG(ss.ss_net_paid) AS avg_store_net_paid
    FROM store_sales ss
    INNER JOIN date_dim d2
        ON ss.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
    GROUP BY ss.ss_item_sk
),
store_returns_join AS (
    SELECT
        sr.sr_item_sk,
        r.r_reason_desc,
        sr.sr_return_quantity,
        sr.sr_return_amt
    FROM store_returns sr
    INNER JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    -- limit to the same year for consistency
    INNER JOIN date_dim dr
        ON sr.sr_returned_date_sk = dr.d_date_sk
    WHERE dr.d_year = 2001
)
SELECT
    csb.cp_catalog_number,
    csb.cp_catalog_page_number,
    csb.i_brand,
    csb.i_category,
    SUM(csb.cs_net_paid) AS total_net_paid,
    AVG(csb.cs_ext_sales_price) AS avg_ext_sales_price,
    RANK() OVER (PARTITION BY csb.d_year ORDER BY SUM(csb.cs_net_paid) DESC) AS rank_by_year,
    CASE WHEN ssa.avg_store_net_paid IS NULL THEN 0
         ELSE SUM(csb.cs_net_paid) / ssa.avg_store_net_paid END AS sales_vs_store_ratio,
    COALESCE(SUM(srr.sr_return_amt), 0) AS total_return_amount,
    MAX(csb.wp_url) FILTER (WHERE csb.wp_url IS NOT NULL) AS sample_page_url,
    MAX(csb.web_name) FILTER (WHERE csb.web_name IS NOT NULL) AS sample_site_name
FROM catalog_sales_base csb
LEFT JOIN store_sales_agg ssa
    ON csb.cs_item_sk = ssa.ss_item_sk
LEFT JOIN store_returns_join srr
    ON csb.cs_item_sk = srr.sr_item_sk
GROUP BY
    csb.cp_catalog_number,
    csb.cp_catalog_page_number,
    csb.i_brand,
    csb.i_category,
    csb.d_year,
    ssa.avg_store_net_paid,
    csb.wp_url,
    csb.web_name
ORDER BY rank_by_year
LIMIT 20
