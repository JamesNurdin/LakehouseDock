WITH joined_data AS (
    SELECT
        d.d_date AS d_date,
        s.s_store_id AS s_store_id,
        s.s_store_name AS s_store_name,
        s.s_state AS s_state,
        cd.cd_gender AS cd_gender,
        hd.hd_buy_potential AS hd_buy_potential,
        ib.ib_lower_bound AS ib_lower_bound,
        ib.ib_upper_bound AS ib_upper_bound,
        cp.cp_type AS cp_type,
        cc.cc_class AS cc_class,
        r.r_reason_desc AS r_reason_desc,
        ss.ss_ext_sales_price AS store_sales_ext,
        cs.cs_ext_sales_price AS catalog_sales_ext,
        ws.ws_ext_sales_price AS web_sales_ext,
        wr.wr_return_amt AS return_amt,
        inv.inv_quantity_on_hand AS inv_qty_on_hand
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'F'
      AND ib.ib_upper_bound >= 50000
      AND cp.cp_type = 'C'
      AND cc.cc_class = 'Small'
),
aggregated AS (
    SELECT
        d_date,
        s_store_id,
        s_store_name,
        s_state,
        cd_gender,
        hd_buy_potential,
        SUM(store_sales_ext) AS total_store_sales,
        SUM(catalog_sales_ext) AS total_catalog_sales,
        SUM(web_sales_ext) AS total_web_sales,
        SUM(return_amt) AS total_return_amt,
        SUM(store_sales_ext + catalog_sales_ext + web_sales_ext - return_amt) AS net_sales
    FROM joined_data
    GROUP BY d_date, s_store_id, s_store_name, s_state, cd_gender, hd_buy_potential
    HAVING SUM(store_sales_ext) > 10000
)
SELECT
    d_date,
    s_store_id,
    s_store_name,
    s_state,
    cd_gender,
    hd_buy_potential,
    total_store_sales,
    total_catalog_sales,
    total_web_sales,
    total_return_amt,
    net_sales,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY net_sales DESC) AS sales_rank
FROM aggregated
WHERE net_sales > (
    SELECT AVG(net_sales)
    FROM (
        SELECT SUM(store_sales_ext + catalog_sales_ext + web_sales_ext - return_amt) AS net_sales
        FROM joined_data
        GROUP BY s_store_id
    ) avg_sub
)
ORDER BY net_sales DESC
LIMIT 100
