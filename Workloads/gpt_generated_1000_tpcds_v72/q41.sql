WITH base AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(cs.cs_net_profit)       AS total_catalog_profit
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs    ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws       ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr     ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc     ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp     ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.promotion p        ON p.p_start_date_sk = d.d_date_sk
    JOIN tpcds.reason r           ON wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.ship_mode sm       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_site ws_site   ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
      AND cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY ROLLUP (d.d_year, p.p_promo_name)
)
SELECT
    d_year,
    p_promo_name,
    total_catalog_sales,
    total_web_sales,
    total_store_sales,
    total_catalog_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
    CASE
        WHEN total_catalog_profit > (SELECT AVG(total_catalog_profit) FROM base) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg
FROM base
ORDER BY d_year DESC, total_catalog_sales DESC
LIMIT 100
