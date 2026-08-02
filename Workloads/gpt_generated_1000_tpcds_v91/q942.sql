WITH ss_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_item_sk, ss.ss_store_sk, ss.ss_hdemo_sk, d.d_year
),
joined_data AS (
    SELECT
        s.s_store_name,
        s.s_store_sk,
        i.i_category,
        d_cs_sold.d_year,
        SUM(ss.store_net_paid) AS total_store_net_paid,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(wr.wr_net_loss) AS total_web_returns_loss,
        (
            SELECT SUM(ss2.ss_net_paid)
            FROM store_sales ss2
            WHERE ss2.ss_store_sk = s.s_store_sk
        ) AS overall_store_net_paid
    FROM ss_agg ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN income_band ib ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_cs_bill ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
    JOIN household_demographics hd_cs_ship ON cs.cs_ship_hdemo_sk = hd_cs_ship.hd_demo_sk
    JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN date_dim d_cs_ship ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
    JOIN date_dim d_wr_returned ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    WHERE s.s_store_sk IN (
        SELECT ss2.ss_store_sk
        FROM store_sales ss2
        WHERE ss2.ss_quantity > 5
    )
    GROUP BY ROLLUP(s.s_store_name, s.s_store_sk, i.i_category, d_cs_sold.d_year)
)
SELECT
    s_store_name,
    i_category,
    d_year,
    total_store_net_paid,
    total_catalog_sales,
    total_web_sales,
    total_web_returns_loss,
    overall_store_net_paid,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_store_net_paid DESC) AS store_rank
FROM joined_data
ORDER BY total_store_net_paid DESC
LIMIT 100
