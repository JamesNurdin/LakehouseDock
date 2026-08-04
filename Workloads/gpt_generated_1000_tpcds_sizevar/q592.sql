WITH catalog_exclusive AS (
        SELECT cs_item_sk
        FROM catalog_sales
        EXCEPT
        SELECT ws_item_sk
        FROM web_sales
    ),
    active_store_ids AS (
        SELECT s_store_sk
        FROM store
        INTERSECT
        SELECT sr_store_sk
        FROM store_returns
    ),
    joined AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            ws.ws_ext_sales_price,
            ws.ws_net_profit,
            s2.s_store_sk,
            sr.sr_return_quantity,
            t.t_hour,
            cc.cc_country,
            ib1.ib_upper_bound,
            wp.wp_type,
            we.web_name,
            avg_price_sub.avg_price,
            EXISTS (SELECT 1 FROM store_returns sr2 WHERE sr2.sr_item_sk = cs.cs_item_sk) AS has_store_return,
            CASE WHEN cs.cs_item_sk IN (SELECT cs_item_sk FROM catalog_exclusive) THEN 1 ELSE 0 END AS catalog_exclusive_flag,
            CASE WHEN s2.s_store_sk IN (SELECT s_store_sk FROM active_store_ids) THEN 1 ELSE 0 END AS active_store_flag
        FROM time_dim t
        LEFT JOIN catalog_sales cs
            ON cs.cs_sold_time_sk = t.t_time_sk
        LEFT JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN warehouse w_cat
            ON cs.cs_warehouse_sk = w_cat.w_warehouse_sk
        LEFT JOIN promotion p_cat
            ON cs.cs_promo_sk = p_cat.p_promo_sk
        LEFT JOIN customer_demographics cd_bill
            ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        LEFT JOIN household_demographics hd_bill
            ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        LEFT JOIN income_band ib1
            ON hd_bill.hd_income_band_sk = ib1.ib_income_band_sk
        LEFT JOIN web_sales ws
            ON ws.ws_sold_time_sk = t.t_time_sk
           AND ws.ws_item_sk = cs.cs_item_sk
        LEFT JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_site we
            ON ws.ws_web_site_sk = we.web_site_sk
        LEFT JOIN warehouse w_web
            ON ws.ws_warehouse_sk = w_web.w_warehouse_sk
        LEFT JOIN promotion p_web
            ON ws.ws_promo_sk = p_web.p_promo_sk
        LEFT JOIN customer_demographics cd_ws_bill
            ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
        LEFT JOIN household_demographics hd_ws_bill
            ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
        LEFT JOIN store_returns sr
            ON sr.sr_return_time_sk = t.t_time_sk
        LEFT JOIN store s2
            ON sr.sr_store_sk = s2.s_store_sk
        LEFT JOIN customer_demographics cd_sr
            ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
        LEFT JOIN household_demographics hd_sr
            ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
        LEFT JOIN income_band ib2
            ON hd_sr.hd_income_band_sk = ib2.ib_income_band_sk
        LEFT JOIN web_returns wr
            ON wr.wr_returned_time_sk = t.t_time_sk
           AND wr.wr_order_number = ws.ws_order_number
        LEFT JOIN customer_demographics cd_wr_refunded
            ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
        LEFT JOIN household_demographics hd_wr_refunded
            ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
        LEFT JOIN LATERAL (
            SELECT AVG(cs2.cs_ext_sales_price) AS avg_price
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = cs.cs_item_sk
        ) avg_price_sub ON TRUE
        WHERE t.t_hour BETWEEN 8 AND 20
          AND cc.cc_country = 'United States'
          AND ib1.ib_upper_bound > 50000
    )
SELECT
    cs_item_sk,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws_ext_sales_price) AS total_web_sales,
    (SUM(cs_net_profit) + SUM(ws_net_profit)) AS total_profit,
    avg_price,
    has_store_return,
    catalog_exclusive_flag,
    active_store_flag,
    ROW_NUMBER() OVER (ORDER BY (SUM(cs_net_profit) + SUM(ws_net_profit)) DESC) AS profit_rank
FROM joined
GROUP BY
    cs_item_sk,
    avg_price,
    has_store_return,
    catalog_exclusive_flag,
    active_store_flag
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
