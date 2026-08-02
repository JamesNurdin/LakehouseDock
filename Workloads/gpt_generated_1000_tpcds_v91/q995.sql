WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_item_id,
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        ss.ss_ext_sales_price AS ss_sales,
        ss.ss_quantity AS ss_quantity,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        cs.cs_ext_sales_price AS cs_sales,
        cs.cs_quantity AS cs_quantity,
        ws.ws_ext_sales_price AS ws_sales,
        ws.ws_quantity AS ws_quantity,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cc.cc_call_center_id,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        wp.wp_type,
        wsite.web_name,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
           AND sr.sr_item_sk = ss.ss_item_sk
           AND sr.sr_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN household_demographics hd_ws_bill
        ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    LEFT JOIN household_demographics hd_ws_ship
        ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    WHERE i.i_current_price > 20
),
union_data AS (
    SELECT
        s_store_id,
        i_item_id,
        i_product_name,
        ss_sales,
        cs_sales,
        ws_sales,
        sr_return_amt,
        inv_quantity_on_hand,
        ib_lower_bound,
        ib_upper_bound
    FROM base
    WHERE cs_sales IS NOT NULL
    UNION ALL
    SELECT
        s_store_id,
        i_item_id,
        i_product_name,
        ss_sales,
        cs_sales,
        ws_sales,
        sr_return_amt,
        inv_quantity_on_hand,
        ib_lower_bound,
        ib_upper_bound
    FROM base
    WHERE ws_sales IS NOT NULL
),
agg AS (
    SELECT
        s_store_id,
        i_item_id,
        i_product_name,
        SUM(ss_sales) AS total_store_sales,
        SUM(cs_sales) AS total_catalog_sales,
        SUM(ws_sales) AS total_web_sales,
        SUM(sr_return_amt) AS total_returns,
        SUM(ss_sales + cs_sales + ws_sales - COALESCE(sr_return_amt, 0)) AS net_revenue
    FROM union_data
    GROUP BY s_store_id, i_item_id, i_product_name, ib_lower_bound, ib_upper_bound
)
SELECT
    s_store_id,
    i_item_id,
    i_product_name,
    total_store_sales,
    total_catalog_sales,
    total_web_sales,
    total_returns,
    net_revenue,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY net_revenue DESC) AS sales_rank
FROM agg
ORDER BY net_revenue DESC
LIMIT 100
