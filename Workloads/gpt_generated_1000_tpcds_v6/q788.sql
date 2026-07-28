WITH cs_detail AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(*) AS catalog_orders
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_promo_sk, cs.cs_bill_hdemo_sk, cs.cs_ship_hdemo_sk, cs.cs_warehouse_sk, cs.cs_catalog_page_sk
),
agg AS (
    SELECT
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        p.p_promo_name AS p_promo_name,
        cp.cp_type AS cp_type,
        ib.ib_lower_bound AS ib_lower_bound,
        ib.ib_upper_bound AS ib_upper_bound,
        w.w_warehouse_name AS w_warehouse_name,
        SUM(cs_detail.total_catalog_sales) AS catalog_sales,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(wr.wr_return_amt) AS total_returns
    FROM cs_detail
    JOIN catalog_page cp
        ON cs_detail.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs_detail.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs_detail.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON cs_detail.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_bill
        ON cs_detail.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
       AND ss.ss_hdemo_sk = hd_bill.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_refunded_hdemo_sk = hd_bill.hd_demo_sk
       AND wr.wr_order_number = ws.ws_order_number
    /* reuse promotion under a different alias */
    JOIN promotion p2
        ON p2.p_item_sk = i.i_item_sk
    /* reuse item under a different alias */
    JOIN item i2
        ON p2.p_item_sk = i2.i_item_sk
    WHERE cp.cp_type = 'monthly'
      AND ib.ib_lower_bound >= 50000
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        p.p_promo_name,
        cp.cp_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        w.w_warehouse_name
)
SELECT
    i_item_id,
    i_product_name,
    p_promo_name,
    cp_type,
    ib_lower_bound,
    ib_upper_bound,
    w_warehouse_name,
    catalog_sales,
    store_sales,
    web_sales,
    total_returns,
    ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY catalog_sales DESC) AS sales_rank
FROM agg
ORDER BY catalog_sales DESC
LIMIT 100
