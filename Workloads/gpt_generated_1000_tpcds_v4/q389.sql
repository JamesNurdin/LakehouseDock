WITH joined_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        cs.cs_ext_sales_price   AS catalog_sales_amount,
        ss.ss_ext_sales_price   AS store_sales_amount,
        ws.ws_ext_sales_price   AS web_sales_amount,
        wr.wr_return_amt        AS web_return_amount,
        c.cc_name,
        cp.cp_department,
        wp.wp_url,
        wsit.web_name,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand,
        r.r_reason_desc
    FROM catalog_sales cs
    JOIN call_center c               ON cs.cs_call_center_sk = c.cc_call_center_sk
    JOIN catalog_page cp              ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i                       ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p                  ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss               ON ss.ss_item_sk = i.i_item_sk
                                      AND ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws                 ON ws.ws_item_sk = i.i_item_sk
                                      AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site wsit                ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN web_returns wr              ON wr.wr_item_sk = i.i_item_sk
                                      AND wr.wr_order_number = ws.ws_order_number
    JOIN web_page wp                  ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN reason r                     ON wr.wr_reason_sk = r.r_reason_sk
    JOIN inventory inv                ON inv.inv_item_sk = i.i_item_sk
    WHERE c.cc_country = 'United States'
      AND i.i_current_price > 20
      AND p.p_channel_tv = 'Y'
      AND i.i_rec_start_date >= DATE '2001-01-01'
      AND inv.inv_quantity_on_hand > 0
)
SELECT
    i_item_id,
    i_product_name,
    i_category,
    i_brand,
    p_promo_name,
    total_sales,
    total_returns,
    net_profit,
    CASE
        WHEN total_sales > 100000 THEN 'High'
        WHEN total_sales > 50000  THEN 'Medium'
        ELSE 'Low'
    END AS sales_volume_category,
    DENSE_RANK() OVER (ORDER BY net_profit DESC) AS profit_rank
FROM (
    SELECT
        i_item_id,
        i_product_name,
        i_category,
        i_brand,
        p_promo_name,
        SUM(COALESCE(catalog_sales_amount, 0) + COALESCE(store_sales_amount, 0) + COALESCE(web_sales_amount, 0)) AS total_sales,
        SUM(COALESCE(web_return_amount, 0))                                                   AS total_returns,
        SUM(COALESCE(catalog_sales_amount, 0) + COALESCE(store_sales_amount, 0) + COALESCE(web_sales_amount, 0) - COALESCE(web_return_amount, 0)) AS net_profit
    FROM joined_data
    GROUP BY i_item_id, i_product_name, i_category, i_brand, p_promo_name
) agg
ORDER BY net_profit DESC
LIMIT 100
