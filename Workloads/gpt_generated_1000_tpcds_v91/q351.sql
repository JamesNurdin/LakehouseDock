WITH
cs_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        ARRAY[SUM(cs.cs_quantity), SUM(cs.cs_ext_sales_price)] AS metrics_arr
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_quantity > 0
      AND cs.cs_ext_sales_price > 0
      AND cs.cs_sold_date_sk IS NOT NULL
      AND cs.cs_sold_time_sk IS NOT NULL
      AND cs.cs_promo_sk IS NOT NULL
    GROUP BY
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk
),
ws_agg AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_promo_sk,
        SUM(ws.ws_ext_sales_price) AS ws_total_sales,
        SUM(ws.ws_net_profit) AS ws_total_profit,
        COUNT(*) AS ws_order_count
    FROM tpcds.web_sales ws
    WHERE ws.ws_quantity > 0
      AND ws.ws_ext_sales_price > 0
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_promo_sk
),
wr_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_reason_sk,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM tpcds.web_returns wr
    WHERE wr.wr_return_amt > 0
    GROUP BY
        wr.wr_returned_date_sk,
        wr.wr_reason_sk
),
base AS (
    SELECT
        d.d_year,
        cp.cp_department,
        p.p_promo_name,
        cs_agg.total_sales,
        ws.ws_ext_sales_price AS ws_sales_price,
        wr.wr_return_amt,
        s.s_store_name,
        hd_bill.hd_income_band_sk,
        cd_bill.cd_gender,
        metric.metric_val,
        metric.metric_pos,
        wrg.total_net_loss
    FROM cs_agg
    JOIN tpcds.date_dim d
        ON cs_agg.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON cs_agg.cs_sold_time_sk = t.t_time_sk
    JOIN tpcds.catalog_page cp
        ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p
        ON cs_agg.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.customer_demographics cd_bill
        ON cs_agg.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.household_demographics hd_bill
        ON cs_agg.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.customer_demographics cd_ship
        ON cs_agg.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN tpcds.household_demographics hd_ship
        ON cs_agg.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    CROSS JOIN UNNEST(cs_agg.metrics_arr) WITH ORDINALITY AS metric(metric_val, metric_pos)
    JOIN tpcds.web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
       AND ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_sold_time_sk = t.t_time_sk
       AND ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
       AND ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
       AND ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
       AND ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN tpcds.date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN tpcds.date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN tpcds.date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN tpcds.date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN tpcds.date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN tpcds.date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN tpcds.date_dim d_site_open
        ON site.web_open_date_sk = d_site_open.d_date_sk
    JOIN tpcds.date_dim d_site_close
        ON site.web_close_date_sk = d_site_close.d_date_sk
    JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN wr_agg wrg
        ON wrg.wr_returned_date_sk = d.d_date_sk
       AND wrg.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND cp.cp_department = 'Books'
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc LIKE '%size%'
      AND s.s_state = 'OH'
      AND wp.wp_max_ad_count >= 2
      AND s.s_rec_start_date >= DATE '2000-01-01'
),
agg AS (
    SELECT
        d_year,
        cp_department,
        p_promo_name,
        SUM(total_sales) AS total_catalog_sales,
        SUM(ws_sales_price) AS total_web_sales,
        SUM(total_net_loss) AS total_return_loss,
        COUNT(*) AS row_cnt
    FROM base
    GROUP BY
        d_year,
        cp_department,
        p_promo_name
    HAVING SUM(total_sales) > 10000
),
final AS (
    SELECT
        d_year,
        cp_department,
        p_promo_name,
        total_catalog_sales,
        total_web_sales,
        total_return_loss,
        ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_catalog_sales DESC) AS dept_sales_rank,
        (SELECT MAX(p2.p_discount_active) FROM tpcds.promotion p2) AS max_discount_active,
        (SELECT AVG(ws_total_sales) FROM ws_agg) AS avg_ws_total_sales
    FROM agg
)
SELECT
    d_year,
    cp_department,
    p_promo_name,
    total_catalog_sales,
    total_web_sales,
    total_return_loss,
    dept_sales_rank,
    max_discount_active,
    avg_ws_total_sales
FROM final
ORDER BY d_year, total_catalog_sales DESC
