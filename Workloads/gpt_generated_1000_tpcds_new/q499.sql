WITH
    joined_sales AS (
        SELECT
            d.d_date AS sale_date,
            i.i_item_id,
            i.i_category,
            i.i_brand,
            cs.cs_ext_sales_price AS sales_price,
            cs.cs_net_profit AS net_profit,
            p.p_promo_id AS promo_id,
            p.p_discount_active AS promo_active,
            cr.cr_return_amount,
            CAST(NULL AS decimal(7,2)) AS wr_return_amt,
            sr.sr_return_amt,
            inv.inv_quantity_on_hand,
            cd.cd_gender AS gender,
            r.r_reason_desc,
            cc.cc_name AS call_center_name,
            ca.ca_state AS state,
            i.i_item_sk,
            ARRAY[cs.cs_ext_sales_price, cs.cs_net_profit, COALESCE(cr.cr_return_amount,0), COALESCE(sr.sr_return_amt,0)] AS metrics_array
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN date_dim inv_d ON inv.inv_date_sk = inv_d.d_date_sk
        WHERE d.d_year = 2001
          AND i.i_category = 'Sports'
          AND p.p_discount_active = 'Y'
          AND cd.cd_gender = 'M'
          AND ib.ib_lower_bound >= 50000
          AND cc.cc_state = 'CA'
    ),
    web_base AS (
        SELECT
            d2.d_date AS sale_date,
            i2.i_item_id,
            i2.i_category,
            i2.i_brand,
            ws.ws_ext_sales_price AS sales_price,
            ws.ws_net_profit AS net_profit,
            p2.p_promo_id AS promo_id,
            p2.p_discount_active AS promo_active,
            CAST(NULL AS decimal(7,2)) AS cr_return_amount,
            wr2.wr_return_amt,
            CAST(NULL AS decimal(7,2)) AS sr_return_amt,
            inv2.inv_quantity_on_hand,
            cd2.cd_gender AS gender,
            r2.r_reason_desc,
            CAST(NULL AS varchar) AS call_center_name,
            ca2.ca_state AS state,
            i2.i_item_sk,
            ARRAY[ws.ws_ext_sales_price, ws.ws_net_profit, COALESCE(wr2.wr_return_amt,0)] AS metrics_array
        FROM web_sales ws
        JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
        JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
        JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
        JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
        JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
        JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
        JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
        LEFT JOIN web_returns wr2 ON wr2.wr_order_number = ws.ws_order_number AND wr2.wr_item_sk = ws.ws_item_sk
        LEFT JOIN inventory inv2 ON inv2.inv_item_sk = i2.i_item_sk
        LEFT JOIN reason r2 ON wr2.wr_reason_sk = r2.r_reason_sk
        LEFT JOIN date_dim inv_d2 ON inv2.inv_date_sk = inv_d2.d_date_sk
        WHERE d2.d_year = 2001
          AND i2.i_category = 'Sports'
          AND p2.p_discount_active = 'Y'
          AND cd2.cd_gender = 'M'
          AND ib2.ib_lower_bound >= 50000
          AND ca2.ca_state = 'CA'
    ),
    unioned AS (
        SELECT * FROM joined_sales
        UNION
        SELECT * FROM web_base
    ),
    aggregated AS (
        SELECT
            sale_date,
            i_item_id,
            i_item_sk,
            SUM(sales_price) AS total_sales,
            SUM(net_profit) AS total_profit,
            SUM(cr_return_amount) + SUM(wr_return_amt) + SUM(sr_return_amt) AS total_returns,
            MAX(inv_quantity_on_hand) AS latest_inventory,
            call_center_name,
            state,
            (SELECT SUM(inv_quantity_on_hand) FROM inventory inv_sub WHERE inv_sub.inv_item_sk = i_item_sk) AS total_inventory_all_dates,
            array_agg(metrics_array) AS metrics_arrays
        FROM unioned
        GROUP BY sale_date, i_item_id, i_item_sk, call_center_name, state
    ),
    windowed AS (
        SELECT
            *,
            LAG(total_sales) OVER (PARTITION BY i_item_id ORDER BY sale_date) AS prev_day_sales
        FROM aggregated
    )
SELECT
    w.sale_date,
    w.i_item_id,
    w.total_sales,
    w.total_profit,
    w.total_returns,
    w.latest_inventory,
    w.total_inventory_all_dates,
    w.prev_day_sales,
    metric
FROM windowed w
CROSS JOIN UNNEST(w.metrics_arrays) AS t(inner_arr)
CROSS JOIN UNNEST(inner_arr) AS t(metric)
ORDER BY w.sale_date DESC, w.total_sales DESC
LIMIT 100
